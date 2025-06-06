{*
* JavaScript para controlar el carrito de compras
*}

<script type="text/javascript">
var limitedProducts = {$limited_products|json_encode};

$(document).ready(function() {
    console.log('Productos limitados en carrito:', limitedProducts);
    
    // Función para bloquear controles del carrito
    function blockCartControls() {
        limitedProducts.forEach(function(product) {
            if (product.current_quantity >= product.limit) {
                // Buscar los controles del producto en el carrito
                var productRow = $('[data-id-product="' + product.id_product + '"], tr[data-id-product="' + product.id_product + '"]');
                
                if (productRow.length === 0) {
                    // Buscar por otros selectores
                    productRow = $('.cart-item').filter(function() {
                        return $(this).find('[data-id-product="' + product.id_product + '"]').length > 0;
                    });
                }
                
                // Bloquear input de cantidad
                productRow.find('input[name*="quantity"], input.cart-line-product-quantity, .js-cart-line-product-quantity').each(function() {
                    $(this).attr('max', product.current_quantity);
                    $(this).val(product.current_quantity);
                    $(this).prop('readonly', true);
                    $(this).addClass('limitador-blocked');
                });
                
                // Bloquear botones de incrementar
                productRow.find('.bootstrap-touchspin-up, .touchspin-up, .qty-up, .btn-touchspin-up, .js-increment-button').each(function() {
                    $(this).prop('disabled', true);
                    $(this).addClass('limitador-blocked');
                    $(this).off('click').on('click', function(e) {
                        e.preventDefault();
                        e.stopPropagation();
                        alert('No puedes agregar más unidades. Límite máximo: ' + product.limit);
                        return false;
                    });
                });
                
                // Agregar mensaje visual en el carrito
                if (!productRow.find('.cart-limit-message').length) {
                    var message = '<div class="cart-limit-message alert alert-warning" style="margin: 5px 0; padding: 8px; font-size: 12px;">' +
                                 '<strong>Límite alcanzado:</strong> Máximo ' + product.limit + ' unidades por pedido' +
                                 '</div>';
                    productRow.find('.cart-line-product-quantity, .product-line-grid-body').first().append(message);
                }
            }
        });
    }
    
    // Aplicar controles al cargar
    blockCartControls();
    
    // Re-aplicar después de actualizaciones AJAX del carrito
    $(document).ajaxComplete(function() {
        setTimeout(blockCartControls, 500);
    });
    
    // Interceptar envíos del formulario de checkout
    $('form[id*="checkout"], form[action*="order"]').on('submit', function(e) {
        var hasViolations = false;
        
        limitedProducts.forEach(function(product) {
            if (product.current_quantity > product.limit) {
                hasViolations = true;
            }
        });
        
        if (hasViolations) {
            e.preventDefault();
            alert('Algunos productos en tu carrito exceden los límites permitidos. Por favor, ajusta las cantidades antes de continuar.');
            return false;
        }
    });
});
</script>

<style>
.cart-limit-message {
    background-color: #fff3cd !important;
    border: 1px solid #ffeaa7 !important;
    color: #856404 !important;
    border-radius: 3px !important;
}
</style>