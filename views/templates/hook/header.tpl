{*
* JavaScript para controlar completamente el comportamiento del producto
*}

<script type="text/javascript">
var productLimit = {$product_limit|intval};
var currentQuantity = {$current_quantity|intval};
var limitReached = {if $limit_reached}true{else}false{/if};
var remainingUnits = {$remaining_units|intval};

$(document).ready(function() {
    console.log('Limitador de Unidades - Producto:', productLimit, 'Actual:', currentQuantity, 'Restantes:', remainingUnits);
    
    // Función para bloquear COMPLETAMENTE la interfaz
    function blockProductInterface() {
        // Bloquear todos los inputs de cantidad
        $('input[name="qty"], #quantity_wanted, .qty, input[type="number"]').each(function() {
            $(this).attr('max', currentQuantity);
            $(this).val(currentQuantity);
            $(this).prop('readonly', true);
            $(this).prop('disabled', true);
            $(this).addClass('limitador-blocked');
        });
        
        // Bloquear todos los botones de añadir al carrito
        $('.add-to-cart, #add_to_cart button, .btn-add-to-cart, button[data-button-action="add-to-cart"]').each(function() {
            $(this).prop('disabled', true);
            $(this).addClass('disabled limitador-blocked');
            $(this).attr('title', 'Límite máximo alcanzado');
            $(this).off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                alert('Ya tienes el máximo permitido de este producto en tu carrito (' + productLimit + ' unidades)');
                return false;
            });
        });
        
        // Bloquear botones de incrementar/decrementar
        $('.bootstrap-touchspin-up, .touchspin-up, .qty-up, .btn-touchspin-up').each(function() {
            $(this).prop('disabled', true);
            $(this).addClass('disabled limitador-blocked');
            $(this).off('click').on('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                return false;
            });
        });
        
        // Bloquear formularios de añadir al carrito
        $('form#add-to-cart-or-refresh, .add-to-cart-or-refresh, form[data-link-action="add-to-cart"]').each(function() {
            $(this).off('submit').on('submit', function(e) {
                e.preventDefault();
                e.stopImmediatePropagation();
                alert('Ya tienes el máximo permitido de este producto en tu carrito (' + productLimit + ' unidades)');
                return false;
            });
        });
        
        // Agregar mensaje visual prominente
        if (!$('.limitador-blocked-message').length) {
            var message = '<div class="limitador-blocked-message alert alert-danger" style="margin: 15px 0; padding: 15px; font-weight: bold; border-radius: 5px;">' +
                         '<i class="icon-warning"></i> <strong>¡LÍMITE ALCANZADO!</strong><br>' +
                         'Ya tienes el máximo permitido de este producto (' + productLimit + ' unidades) en tu carrito.<br>' +
                         'Si quieres más unidades, debes hacer varios pedidos separados.' +
                         '</div>';
            
            $('.product-add-to-cart, .product-actions, .add-to-cart').first().prepend(message);
        }
    }
    
    // Función para limitar pero permitir hasta el máximo
    function limitProductInterface() {
        var maxAllowed = remainingUnits;
        
        // Configurar límites en inputs
        $('input[name="qty"], #quantity_wanted, .qty, input[type="number"]').each(function() {
            $(this).attr('max', maxAllowed);
            $(this).prop('readonly', false);
            $(this).prop('disabled', false);
            
            // Validar en tiempo real
            $(this).on('input change keyup', function() {
                var val = parseInt($(this).val()) || 0;
                if (val > maxAllowed) {
                    $(this).val(maxAllowed);
                    if (!$('.limitador-warning').length) {
                        $(this).after('<small class="limitador-warning text-danger" style="display: block; margin-top: 5px; font-weight: bold;">Máximo permitido: ' + maxAllowed + ' unidades</small>');
                    }
                } else {
                    $('.limitador-warning').remove();
                }
            });
        });
        
        // Interceptar TODOS los envíos de formulario
        $('form#add-to-cart-or-refresh, .add-to-cart-or-refresh, form[data-link-action="add-to-cart"], form').each(function() {
            $(this).off('submit.limitador').on('submit.limitador', function(e) {
                var qtyInput = $(this).find('input[name="qty"], #quantity_wanted, .qty, input[type="number"]').first();
                var requestedQty = parseInt(qtyInput.val()) || 1;
                var totalQty = currentQuantity + requestedQty;
                
                if (totalQty > productLimit) {
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    alert('No puedes agregar ' + requestedQty + ' unidades. Solo puedes agregar ' + maxAllowed + ' más.\nLímite total: ' + productLimit + ' unidades por pedido.');
                    return false;
                }
            });
        });
        
        // Interceptar clics en botones
        $('.add-to-cart, #add_to_cart button, .btn-add-to-cart, button[data-button-action="add-to-cart"]').each(function() {
            $(this).off('click.limitador').on('click.limitador', function(e) {
                var qtyInput = $('input[name="qty"], #quantity_wanted, .qty, input[type="number"]').first();
                var requestedQty = parseInt(qtyInput.val()) || 1;
                var totalQty = currentQuantity + requestedQty;
                
                if (totalQty > productLimit) {
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    alert('No puedes agregar ' + requestedQty + ' unidades. Solo puedes agregar ' + maxAllowed + ' más.\nLímite total: ' + productLimit + ' unidades por pedido.');
                    return false;
                }
            });
        });
    }
    
    // Aplicar la lógica correspondiente
    if (limitReached) {
        blockProductInterface();
    } else {
        limitProductInterface();
    }
    
    // Interceptar TODAS las peticiones AJAX de PrestaShop
    var originalAjax = $.ajax;
    $.ajax = function(options) {
        if (options.url && (options.url.indexOf('cart') !== -1 || options.url.indexOf('add') !== -1)) {
            console.log('Interceptando AJAX:', options);
            
            // Si es una petición de agregar al carrito y hemos alcanzado el límite
            if (limitReached) {
                alert('Ya tienes el máximo permitido de este producto en tu carrito (' + productLimit + ' unidades)');
                return false;
            }
        }
        
        return originalAjax.call(this, options);
    };
    
    // Re-aplicar controles después de cualquier cambio
    setInterval(function() {
        if (limitReached) {
            blockProductInterface();
        } else {
            limitProductInterface();
        }
    }, 1000);
    
    // Para PrestaShop 1.7+
    if (typeof prestashop !== 'undefined') {
        prestashop.on('updatedProduct', function(event) {
            setTimeout(function() {
                if (limitReached) {
                    blockProductInterface();
                } else {
                    limitProductInterface();
                }
            }, 100);
        });
    }
});
</script>

<style>
.limitador-blocked {
    opacity: 0.5 !important;
    cursor: not-allowed !important;
    pointer-events: none !important;
}

.limitador-blocked-message {
    background-color: #f8d7da !important;
    border: 1px solid #f5c6cb !important;
    color: #721c24 !important;
    font-size: 14px !important;
    text-align: center !important;
}

.limitador-warning {
    color: #dc3545 !important;
    font-weight: bold !important;
}

.disabled {
    opacity: 0.6 !important;
    cursor: not-allowed !important;
    pointer-events: none !important;
}
</style>