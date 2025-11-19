class ShipmentDocumentsController < ApplicationController
  before_action :set_shipment_document, only: [:show, :edit, :update, :destroy]

  # GET /shipment_documents
  def index
    @shipment_documents = ShipmentDocument.all
  end

  # GET /shipment_documents/1
  def show
  end

  # GET /shipment_documents/new
  def new
    @shipment_document = ShipmentDocument.new
  end

  # GET /shipment_documents/1/edit
  def edit
  end

  # POST /shipment_documents
  def create
    @shipment_document = ShipmentDocument.new(shipment_document_params)

    if @shipment_document.save
      redirect_to @shipment_document, notice: 'Shipment document was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /shipment_documents/1
  def update
    if @shipment_document.update(shipment_document_params)
      redirect_to @shipment_document, notice: 'Shipment document was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /shipment_documents/1
  def destroy
    @shipment_document.destroy
    redirect_to shipment_documents_url, notice: 'Shipment document was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shipment_document
      @shipment_document = ShipmentDocument.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def shipment_document_params
      params.require(:shipment_document).permit(:shipment_id, :document_type, :notes, :file)
    end
end
