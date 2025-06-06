{*
* Template para mostrar el límite en la página del producto
*}

<div id="limitador-info-{$id_product}" class="limitador-unidades-info alert {if $limit_reached}alert-danger{else}alert-info{/if}">
    <i class="icon-info-circle"></i>
    <strong>{l s='Límite de compra:' mod='limitadorunidades'}</strong> {$limit_message|escape:'htmlall':'UTF-8'}
    
    {if $current_quantity > 0}
        <br><small>
            <strong>{l s='Ya tienes:' mod='limitadorunidades'}</strong> {$current_quantity} {if $current_quantity == 1}{l s='unidad' mod='limitadorunidades'}{else}{l s='unidades' mod='limitadorunidades'}{/if} en tu carrito.
            {if $remaining_units > 0}
                {l s='Puedes agregar' mod='limitadorunidades'} {$remaining_units} {if $remaining_units == 1}{l s='unidad más' mod='limitadorunidades'}{else}{l s='unidades más' mod='limitadorunidades'}{/if}.
            {else}
                <strong style="color: #dc3545;">{l s='¡HAS ALCANZADO EL LÍMITE MÁXIMO!' mod='limitadorunidades'}</strong>
            {/if}
        </small>
    {/if}
</div>

{if $limit_reached}
<div id="limitador-blocked-{$id_product}" class="alert alert-danger" style="margin: 15px 0; padding: 15px; text-align: center; font-weight: bold;">
    <i class="icon-ban"></i>
    <strong>¡PRODUCTO BLOQUEADO!</strong><br>
    Ya tienes el máximo permitido ({$product_limit} unidades) en tu carrito.<br>
    <small>Si quieres más unidades, debes hacer varios pedidos separados.</small>
</div>
{/if}

<style>
.limitador-unidades-info {
    margin: 15px 0;
    padding: 15px;
    border-radius: 5px;
    font-size: 14px;
    border: 2px solid;
}

.alert-danger {
    background-color: #f8d7da !important;
    border-color: #f5c6cb !important;
    color: #721c24 !important;
}

.alert-info {
    background-color: #d1ecf1 !important;
    border-color: #bee5eb !important;
    color: #0c5460 !important;
}
</style>