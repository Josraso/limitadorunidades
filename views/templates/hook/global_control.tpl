{*
* Control JavaScript SIMPLE pero EFECTIVO
*}

<script type="text/javascript">
// Variables globales del limitador
window.limitadorData = {
    cartProducts: {$cart_limited_products|json_encode},
    currentProductId: {$current_product_id|intval},
    currentProductLimit: {$current_product_limit|intval},
    currentProductQuantity: {$current_product_quantity|intval},
    currentLimitReached: {if $current_limit_reached}true{else}false{/if}
};

$(document).ready(function() {
    console.log('Limitador Simple - Data:', window.limitadorData);
    
    // Si hemos alcanzado el límite del producto actual
    if (window.limitadorData.currentLimitReached && window.limitadorData.currentProductId > 0) {
        console.log('BLOQUEANDO producto ID:', window.limitadorData.currentProductId);
        
        // Función simple para bloquear todo
        function bloquearTodo() {
            // Bloquear formularios
            $('form').each(function() {
                var $form = $(this);
                if ($form.html().indexOf('add') !== -1 || $form.html().indexOf('cart') !== -1) {
                    $form.find('input, button, select').prop('disabled', true);
                    $form.on('submit', function(e) {
                        e.preventDefault();
                        alert('¡LÍMITE ALCANZADO! Ya tienes el máximo permitido de este producto.');
                        return false;
                    });
                }
            });
            
            // Bloquear botones
            $('button, input[type="submit"]').each(function() {
                var $btn = $(this);
                var text = $btn.text().toLowerCase();
                if (text.indexOf('añadir') !== -1 || text.indexOf('agregar') !== -1 || text.indexOf('add') !== -1) {
                    $btn.prop('disabled', true).css({
                        'opacity': '0.3',
                        'cursor': 'not-allowed'
                    });
                    $btn.on('click', function(e) {
                        e.preventDefault();
                        alert('¡LÍMITE ALCANZADO! Ya tienes el máximo permitido de este producto.');
                        return false;
                    });
                }
            });
            
            // Bloquear inputs de cantidad
            $('input[name="qty"], #quantity_wanted').each(function() {
                $(this).prop('readonly', true).css('opacity', '0.5');
            });
        }
        
        // Aplicar bloqueo
        bloquearTodo();
        
        // Re-aplicar cada 2 segundos
        setInterval(bloquearTodo, 2000);
    }
    
    // Bloquear productos en carrito
    if (window.limitadorData.cartProducts && window.limitadorData.cartProducts.length > 0) {
        window.limitadorData.cartProducts.forEach(function(product) {
            if (product.limit_reached) {
                console.log('Bloqueando en carrito producto ID:', product.id_product);
                
                // Buscar y bloquear controles del carrito
                $('input[name*="quantity"]').each(function() {
                    var $input = $(this);
                    var $row = $input.closest('tr, .cart-item');
                    
                    if ($row.html().indexOf(product.id_product) !== -1) {
                        $input.prop('readonly', true).css('opacity', '0.5');
                        $row.find('.bootstrap-touchspin-up, .qty-up').prop('disabled', true).css('opacity', '0.3');
                    }
                });
            }
        });
    }
});
</script>

<style>
button:disabled, input:disabled {
    opacity: 0.3 !important;
    cursor: not-allowed !important;
}
</style>