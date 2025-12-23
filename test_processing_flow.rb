#!/usr/bin/env ruby
# Test script for complete jute purchase → stock → processing flow
# Usage: bin/rails runner test_processing_flow.rb

puts "=" * 80
puts "Testing Complete Jute Processing Flow"
puts "=" * 80

# Clean up test data from previous runs
puts "\n--- Cleaning up previous test data ---"
begin
  # Clean up processing batches first
  ProcessingBatch.joins("INNER JOIN products ON processing_batches.input_product_id = products.id").where("products.name LIKE 'Test%'").destroy_all rescue nil
  
  # Clean up stock movements (schema-aware)
  if StockMovement.column_names.include?('source_type')
    JutePurchase.joins(:supplier).where("suppliers.name = 'Test Supplier'").find_each do |jp|
      StockMovement.where(source_type: 'JutePurchase', source_id: jp.id).destroy_all
    end
  elsif StockMovement.column_names.include?('reference_type')
    JutePurchase.joins(:supplier).where("suppliers.name = 'Test Supplier'").find_each do |jp|
      StockMovement.where(reference_type: 'JutePurchase', reference_id: jp.id).destroy_all
    end
  end
  
  # Clean up purchases
  JutePurchase.joins(:supplier).where("suppliers.name = 'Test Supplier'").destroy_all
  
  # Clean up stock
  JuteStock.joins(:stock_house).where("stock_houses.name = 'Test Warehouse'").destroy_all rescue nil
  
  # Clean up master data
  Product.where("name LIKE 'Test%' OR name = 'Processing Waste'").destroy_all
  StockHouse.where(name: "Test Warehouse").destroy_all
  Supplier.where(name: "Test Supplier").destroy_all
rescue => e
  puts "  Warning during cleanup: #{e.message}"
end
puts "✓ Cleanup complete"

# Step 1: Create a product if needed
raw_product = Product.find_or_create_by!(name: "Test Raw Jute") do |p|
  p.product_type = "raw"
  p.category = "raw_material"
  p.unit = "kg"
end

processed_product = Product.find_or_create_by!(name: "Test Processed Jute") do |p|
  p.product_type = "processed"
  p.category = "processed"
  p.unit = "kg"
end

puts "\n✓ Products created: #{raw_product.name}, #{processed_product.name}"

# Step 2: Create supplier and stock house
supplier = Supplier.find_or_create_by!(name: "Test Supplier") do |s|
  s.contact_person = "Test Person"
  s.phone = "1234567890"
  s.supplier_type = "regular"  # Add required field
end

stock_house = StockHouse.find_or_create_by!(name: "Test Warehouse") do |sh|
  sh.location = "Test Location"
end

puts "✓ Supplier: #{supplier.name}, Stock House: #{stock_house.name}"

# Step 3: Create a jute purchase
puts "\n--- Creating Jute Purchase ---"
purchase = JutePurchase.create!(
  supplier: supplier,
  stock_house: stock_house,
  product: raw_product,
  purchase_date: Date.today,
  quantity_kg: 1000,
  rate_per_kg: 50,
  total_amount: 50000
)

puts "✓ Purchase created: #{purchase.id}"
puts "  Quantity: #{purchase.quantity_kg} kg"

# Step 4: Verify stock was created
sleep 0.5  # Give callbacks time to run
jute_stock = JuteStock.find_by(product_id: raw_product.id, stock_house: stock_house)

if jute_stock
  puts "✓ JuteStock created: #{jute_stock.id}"
  puts "  Current quantity: #{jute_stock.quantity_value} kg"
else
  puts "✗ ERROR: JuteStock not created!"
  exit 1
end

# Step 5: Verify stock movement was created
movements = if StockMovement.column_names.include?('source_type')
              StockMovement.where(source_type: 'JutePurchase', source_id: purchase.id)
            else
              StockMovement.where(reference_type: 'JutePurchase', reference_id: purchase.id)
            end

puts "✓ Stock movements created: #{movements.count}"
movements.each do |m|
  puts "  - #{m.movement_type}: #{m.movement_quantity} kg"
end

if movements.count == 0
  puts "✗ ERROR: No stock movements created!"
  exit 1
end

# Step 6: Create a processing batch
puts "\n--- Creating Processing Batch ---"
begin
  batch = ProcessingBatch.create!(
    input_product: raw_product,
    input_jute_stock_id: jute_stock.id,
    input_quantity: 500,
    output_product: processed_product,
    output_quantity: 480,
    waste_quantity: 20,
    processed_date: Date.today
  )
  
  puts "✓ Processing batch created: #{batch.id}"
  puts "  Input: #{batch.input_quantity} kg"
  puts "  Output: #{batch.output_quantity} kg"
  puts "  Waste: #{batch.waste_quantity} kg"
rescue => e
  puts "✗ ERROR creating processing batch: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Step 7: Verify processing movements
sleep 0.5
process_movements = if StockMovement.column_names.include?('source_type')
                      StockMovement.where(source_type: 'ProcessingBatch', source_id: batch.id)
                    else
                      StockMovement.where(reference_type: 'ProcessingBatch', reference_id: batch.id)
                    end

puts "\n✓ Processing movements created: #{process_movements.count}"
process_movements.each do |m|
  stock = m.jute_stock
  product_name = stock&.product&.name || 'unknown'
  puts "  - #{m.movement_type}: #{m.movement_quantity} kg (#{product_name})"
end

if process_movements.count == 0
  puts "✗ ERROR: No processing movements created!"
  exit 1
end

# Step 8: Verify stock quantities updated correctly
jute_stock.reload
output_stock = JuteStock.find_by(product_id: processed_product.id, stock_house: stock_house)
waste_product = Product.find_by(name: 'Processing Waste')
waste_stock = waste_product ? JuteStock.find_by(product_id: waste_product.id, stock_house: stock_house) : nil

puts "\n--- Final Stock Quantities ---"
puts "Raw jute (#{raw_product.name}): #{jute_stock.quantity_value} kg (expected: 500 kg)"
puts "Processed jute (#{processed_product.name}): #{output_stock&.quantity_value || 0} kg (expected: 480 kg)"
puts "Waste: #{waste_stock&.quantity_value || 0} kg (expected: 20 kg)"

# Verify expectations
errors = []
errors << "Raw stock incorrect: #{jute_stock.quantity_value} != 500" unless jute_stock.quantity_value == 500
errors << "Output stock incorrect: #{output_stock&.quantity_value} != 480" unless output_stock&.quantity_value == 480
errors << "Waste stock incorrect: #{waste_stock&.quantity_value} != 20" unless waste_stock&.quantity_value == 20

if errors.empty?
  puts "\n" + "=" * 80
  puts "✓ ALL TESTS PASSED!"
  puts "=" * 80
else
  puts "\n" + "=" * 80
  puts "✗ TESTS FAILED:"
  errors.each { |e| puts "  - #{e}" }
  puts "=" * 80
  exit 1
end
