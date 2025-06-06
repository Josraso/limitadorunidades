{*
* Template de configuración del módulo Limitador de Unidades
*}

{* Incluir Select2 CSS y JS *}
<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

<div class="panel">
    <div class="panel-heading">
        <i class="icon-cogs"></i>
        {l s='Configuración General' mod='limitadorunidades'}
    </div>
    <div class="panel-body">
        <form id="configuration_form" class="defaultForm form-horizontal" action="{$smarty.server.REQUEST_URI|escape:'htmlall':'UTF-8'}" method="post" enctype="multipart/form-data" novalidate="">
            <div class="form-group">
                <label class="control-label col-lg-3">
                    <span class="label-tooltip" data-toggle="tooltip" title="{l s='Activar o desactivar el módulo' mod='limitadorunidades'}">
                        {l s='Módulo Activo' mod='limitadorunidades'}
                    </span>
                </label>
                <div class="col-lg-9">
                    <span class="switch prestashop-switch fixed-width-lg">
                        <input type="radio" name="LIMITADOR_UNIDADES_ACTIVE" id="LIMITADOR_UNIDADES_ACTIVE_on" value="1" {if $limitador_active}checked="checked"{/if}>
                        <label for="LIMITADOR_UNIDADES_ACTIVE_on">{l s='Sí' mod='limitadorunidades'}</label>
                        <input type="radio" name="LIMITADOR_UNIDADES_ACTIVE" id="LIMITADOR_UNIDADES_ACTIVE_off" value="0" {if !$limitador_active}checked="checked"{/if}>
                        <label for="LIMITADOR_UNIDADES_ACTIVE_off">{l s='No' mod='limitadorunidades'}</label>
                        <a class="slide-button btn"></a>
                    </span>
                </div>
            </div>
            
            <div class="form-group">
                <label class="control-label col-lg-3 required">
                    <span class="label-tooltip" data-toggle="tooltip" title="{l s='Mensaje que se mostrará al usuario. Usa {limit} para mostrar el número límite' mod='limitadorunidades'}">
                        {l s='Mensaje de límite' mod='limitadorunidades'}
                    </span>
                </label>
                <div class="col-lg-9">
                    <textarea name="LIMITADOR_UNIDADES_MESSAGE" rows="3" class="form-control">{$limitador_message|escape:'htmlall':'UTF-8'}</textarea>
                    <p class="help-block">{l s='Usa {limit} para mostrar el número límite en el mensaje' mod='limitadorunidades'}</p>
                </div>
            </div>
            
            <div class="panel-footer">
                <button type="submit" value="1" id="configuration_form_submit_btn" name="submitLimitadorUnidadesConfig" class="btn btn-default pull-right">
                    <i class="process-icon-save"></i> {l s='Guardar' mod='limitadorunidades'}
                </button>
            </div>
        </form>
    </div>
</div>

<div class="panel">
    <div class="panel-heading">
        <i class="icon-shopping-cart"></i>
        {l s='Agregar Límite a Producto' mod='limitadorunidades'}
    </div>
    <div class="panel-body">
        <form id="add_product_form" class="defaultForm form-horizontal" action="{$smarty.server.REQUEST_URI|escape:'htmlall':'UTF-8'}" method="post">
            <div class="form-group">
                <label class="control-label col-lg-3 required">
                    {l s='Buscar Producto' mod='limitadorunidades'}
                </label>
                <div class="col-lg-6">
                    <select id="product_search" name="id_product" class="form-control" required style="width: 100%;">
                        <option value="">{l s='Escribe para buscar por nombre, referencia o ID...' mod='limitadorunidades'}</option>
                    </select>
                    <p class="help-block">{l s='Puedes buscar por nombre del producto, referencia o ID' mod='limitadorunidades'}</p>
                </div>
            </div>
            
            <div class="form-group">
                <label class="control-label col-lg-3 required">
                    {l s='Límite de Unidades' mod='limitadorunidades'}
                </label>
                <div class="col-lg-3">
                    <input type="number" name="max_units" class="form-control" min="1" required placeholder="Ej: 5">
                    <p class="help-block">{l s='Máximo número de unidades por pedido' mod='limitadorunidades'}</p>
                </div>
            </div>
            
            <div class="panel-footer">
                <button type="submit" value="1" name="submitAddProductLimit" class="btn btn-default pull-right">
                    <i class="process-icon-save"></i> {l s='Agregar Límite' mod='limitadorunidades'}
                </button>
            </div>
        </form>
    </div>
</div>

<div class="panel">
    <div class="panel-heading">
        <i class="icon-list"></i>
        {l s='Productos con Límites Configurados' mod='limitadorunidades'}
    </div>
    <div class="panel-body">
        {if $products_with_limits}
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>{l s='ID' mod='limitadorunidades'}</th>
                            <th>{l s='Nombre del Producto' mod='limitadorunidades'}</th>
                            <th>{l s='Referencia' mod='limitadorunidades'}</th>
                            <th>{l s='Límite de Unidades' mod='limitadorunidades'}</th>
                            <th>{l s='Estado' mod='limitadorunidades'}</th>
                            <th>{l s='Acciones' mod='limitadorunidades'}</th>
                        </tr>
                    </thead>
                    <tbody>
                        {foreach from=$products_with_limits item=product}
                            <tr>
                                <td>{$product.id_product|escape:'htmlall':'UTF-8'}</td>
                                <td><strong>{$product.product_name|escape:'htmlall':'UTF-8'}</strong></td>
                                <td><code>{$product.reference|escape:'htmlall':'UTF-8'}</code></td>
                                <td><span class="badge badge-info">{$product.max_units|escape:'htmlall':'UTF-8'} unidades</span></td>
                                <td>
                                    {if $product.active}
                                        <span class="badge badge-success">{l s='Activo' mod='limitadorunidades'}</span>
                                    {else}
                                        <span class="badge badge-danger">{l s='Inactivo' mod='limitadorunidades'}</span>
                                    {/if}
                                </td>
                                <td>
                                    <a href="{$smarty.server.REQUEST_URI|escape:'htmlall':'UTF-8'}&deleteProductLimit=1&id_limitador={$product.id_limitador|escape:'htmlall':'UTF-8'}" 
                                       class="btn btn-danger btn-xs" 
                                       onclick="return confirm('{l s='¿Estás seguro de eliminar este límite?' mod='limitadorunidades'}')">
                                        <i class="icon-trash"></i> {l s='Eliminar' mod='limitadorunidades'}
                                    </a>
                                </td>
                            </tr>
                        {/foreach}
                    </tbody>
                </table>
            </div>
        {else}
            <div class="alert alert-info">
                <i class="icon-info-circle"></i>
                {l s='No hay productos con límites configurados. Agrega tu primer producto usando el formulario de arriba.' mod='limitadorunidades'}
            </div>
        {/if}
    </div>
</div>

<script type="text/javascript">
$(document).ready(function() {
    console.log('Inicializando Select2...');
    
    // Inicializar Select2 para búsqueda de productos
    $('#product_search').select2({
        placeholder: 'Escribe para buscar productos...',
        allowClear: true,
        minimumInputLength: 2,
        language: {
            inputTooShort: function () {
                return 'Escribe al menos 2 caracteres para buscar';
            },
            noResults: function () {
                return 'No se encontraron productos';
            },
            searching: function () {
                return 'Buscando...';
            }
        },
        ajax: {
            url: function() {
                // Construir URL para AJAX
                var baseUrl = window.location.href;
                if (baseUrl.indexOf('&ajax=1') === -1) {
                    baseUrl += '&ajax=1&action=searchProducts';
                }
                return baseUrl;
            },
            dataType: 'json',
            delay: 300,
            data: function (params) {
                return {
                    q: params.term,
                    action: 'searchProducts',
                    ajax: 1
                };
            },
            processResults: function (data) {
                console.log('Resultados recibidos:', data);
                return {
                    results: data
                };
            },
            cache: true
        },
        escapeMarkup: function (markup) {
            return markup;
        },
        templateResult: function(product) {
            if (product.loading) return product.text;
            return '<div><strong>' + product.text + '</strong></div>';
        },
        templateSelection: function(product) {
            return product.text || product.id;
        }
    });

    // Debug
    $('#product_search').on('select2:open', function (e) {
        console.log('Select2 abierto');
    });

    $('#product_search').on('select2:select', function (e) {
        var data = e.params.data;
        console.log('Producto seleccionado:', data);
    });
});
</script>

<style>
.select2-container {
    width: 100% !important;
}

.select2-container--default .select2-search--inline .select2-search__field {
    margin-top: 5px;
}

.select2-container--default .select2-selection--single {
    height: 34px;
    border: 1px solid #ccc;
    border-radius: 4px;
}

.select2-container--default .select2-selection--single .select2-selection__rendered {
    line-height: 32px;
    padding-left: 12px;
}

.select2-container--default .select2-selection--single .select2-selection__arrow {
    height: 32px;
}

.badge {
    display: inline-block;
    padding: 3px 7px;
    font-size: 11px;
    font-weight: bold;
    line-height: 1;
    color: #fff;
    text-align: center;
    white-space: nowrap;
    vertical-align: baseline;
    border-radius: 3px;
}

.badge-info {
    background-color: #5bc0de;
}

.badge-success {
    background-color: #5cb85c;
}

.badge-danger {
    background-color: #d9534f;
}

code {
    padding: 2px 4px;
    font-size: 90%;
    color: #c7254e;
    background-color: #f9f2f4;
    border-radius: 4px;
}
</style>