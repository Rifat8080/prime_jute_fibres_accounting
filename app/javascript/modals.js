document.addEventListener("turbo:load", () => {
    // Modals
    const supplierModal = document.getElementById('supplier-modal');
    const stockHouseModal = document.getElementById('stock-house-modal');

    if (supplierModal) {
        const newSupplierForm = document.getElementById('new_supplier_form');
        newSupplierForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const formData = new FormData(newSupplierForm);
            fetch('/suppliers', {
                method: 'POST',
                body: formData,
                headers: {
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.id) {
                    const supplierSelect = document.getElementById('jute_purchase_supplier_id');
                    const newOption = new Option(data.name, data.id, true, true);
                    supplierSelect.add(newOption);
                    closeModal('supplier-modal');
                } else {
                    // Handle errors
                    const errorExplanation = document.getElementById('error_explanation');
                    if (errorExplanation) {
                        let errorList = '<ul>';
                        for (const [key, value] of Object.entries(data.errors)) {
                            errorList += `<li>${key} ${value}</li>`;
                        }
                        errorList += '</ul>';
                        errorExplanation.innerHTML = `<h2>Errors prohibited this supplier from being saved:</h2>${errorList}`;
                    }
                }
            });
        });
    }

    if (stockHouseModal) {
        const newStockHouseForm = document.getElementById('new_stock_house_form');
        newStockHouseForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const formData = new FormData(newStockHouseForm);
            fetch('/stock_houses', {
                method: 'POST',
                body: formData,
                headers: {
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.id) {
                    const stockHouseSelect = document.getElementById('jute_purchase_stock_house_id');
                    const newOption = new Option(data.name, data.id, true, true);
                    stockHouseSelect.add(newOption);
                    closeModal('stock-house-modal');
                } else {
                    // Handle errors
                    const errorExplanation = document.getElementById('error_explanation');
                    if (errorExplanation) {
                        let errorList = '<ul>';
                        for (const [key, value] of Object.entries(data.errors)) {
                            errorList += `<li>${key} ${value}</li>`;
                        }
                        errorList += '</ul>';
                        errorExplanation.innerHTML = `<h2>Errors prohibited this stock_house from being saved:</h2>${errorList}`;
                    }
                }
            });
        });
    }
});

function openModal(modalId) {
  document.getElementById(modalId).style.display = 'block';
}

function closeModal(modalId) {
  document.getElementById(modalId).style.display = 'none';
}
