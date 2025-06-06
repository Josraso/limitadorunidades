<?php
/**
 * Módulo Limitador de Unidades para PrestaShop
 * Permite limitar las unidades de compra por productos simples
 *
 * @author Josraso
 * @version 3.0.0
 * @license MIT
 */

if (!defined('_PS_VERSION_')) {
    exit;
}

class LimitadorUnidades extends Module
{
    public function __construct()
    {
        $this->name = 'limitadorunidades';
        $this->tab = 'administration';
        $this->version = '3.0.0';
        $this->author = 'Josraso';
        $this->need_instance = 0;
        $this->ps_versions_compliancy = array('min' => '1.7', 'max' => _PS_VERSION_);
        $this->bootstrap = true;

        parent::__construct();

        $this->displayName = $this->l('Limitador de Unidades');
        $this->description = $this->l('Limita las unidades de compra por productos simples en cada pedido individual');
        $this->confirmUninstall = $this->l('¿Estás seguro de que quieres desinstalar este módulo?');

        // INTERCEPTAR AQUÍ TODAS LAS ACCIONES DEL CARRITO
        $this->interceptAllCartActions();

        // Manejar AJAX si está presente
        if (Tools::getValue('ajax') && Tools::getValue('action') == 'searchProducts') {
            $this->ajaxProcessSearchProducts();
        }
    }

    private function interceptAllCartActions()
    {
        // Solo si el módulo está activo
        if (!Configuration::get('LIMITADOR_UNIDADES_ACTIVE')) {
            return;
        }

        // Verificar si es una acción de carrito
        $is_cart_action = false;
        $id_product = 0;
        $qty = 0;

        // Detectar diferentes formas de agregar al carrito
        if (Tools::getValue('controller') == 'cart' || 
            Tools::isSubmit('add') || 
            Tools::getValue('add') || 
            Tools::getValue('action') == 'update' ||
            isset($_POST['submitCustomizedDatas']) ||
            isset($_GET['add']) ||
            isset($_POST['qty'])) {
            
            $is_cart_action = true;
            
            // Obtener ID del producto de diferentes fuentes
            $id_product = (int)(
                Tools::getValue('id_product') ?: 
                Tools::getValue('add') ?: 
                Tools::getValue('pid') ?:
                0
            );
            
            // Obtener cantidad de diferentes fuentes
            $qty = (int)(
                Tools::getValue('qty') ?: 
                Tools::getValue('quantity') ?: 
                1
            );
        }

        // Si es una acción de carrito, validar límites
        if ($is_cart_action && $id_product > 0) {
            $this->enforceProductLimit($id_product, $qty);
        }
    }

    private function enforceProductLimit($id_product, $qty)
    {
        $limit = $this->getProductLimit($id_product);
        
        if ($limit > 0) {
            $current_quantity = $this->getCurrentCartQuantity($id_product);
            $new_total = $current_quantity + $qty;
            
            // Si excede el límite, forzar la cantidad al límite y detener
            if ($new_total > $limit || $current_quantity >= $limit) {
                // Forzar la cantidad del carrito al límite
                if ($this->context && $this->context->cart) {
                    $this->context->cart->updateQty($limit, $id_product, 0);
                }
                
                // Preparar mensaje de error
                $message = str_replace('{limit}', $limit, Configuration::get('LIMITADOR_UNIDADES_MESSAGE'));
                $error_message = sprintf(
                    $this->l('No se pueden agregar más unidades. %s'),
                    $message
                );
                
                // Si es petición AJAX
                if (Tools::getValue('ajax') || 
                    isset($_SERVER['HTTP_X_REQUESTED_WITH']) && 
                    $_SERVER['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest') {
                    
                    header('Content-Type: application/json');
                    die(json_encode(array(
                        'hasError' => true,
                        'errors' => array($error_message),
                        'success' => false
                    )));
                }
                
                // Si es petición normal, redirigir con error
                if (isset($_SERVER['HTTP_REFERER'])) {
                    $redirect_url = $_SERVER['HTTP_REFERER'];
                    $separator = (strpos($redirect_url, '?') !== false) ? '&' : '?';
                    $redirect_url .= $separator . 'limitador_error=' . urlencode($error_message);
                    
                    header('Location: ' . $redirect_url);
                    exit;
                }
                
                // Como último recurso, mostrar el error y parar
                die($error_message);
            }
        }
    }

    public function install()
    {
        if (Shop::isFeatureActive()) {
            Shop::setContext(Shop::CONTEXT_ALL);
        }

        return parent::install()
            && $this->registerHook('displayProductAdditionalInfo')
            && $this->registerHook('displayHeader')
            && $this->registerHook('displayBeforeBodyClosingTag')
            && $this->registerHook('actionCartSave')
            && $this->createTables()
            && $this->installConfiguration();
    }

    public function uninstall()
    {
        return parent::uninstall()
            && $this->deleteTables()
            && $this->deleteConfiguration();
    }

    protected function createTables()
    {
        $sql = array();

        $sql[] = 'CREATE TABLE IF NOT EXISTS `' . _DB_PREFIX_ . 'limitador_unidades` (
            `id_limitador` int(11) NOT NULL AUTO_INCREMENT,
            `id_product` int(11) NOT NULL,
            `max_units` int(11) NOT NULL DEFAULT 0,
            `active` tinyint(1) NOT NULL DEFAULT 1,
            `date_add` datetime NOT NULL,
            `date_upd` datetime NOT NULL,
            PRIMARY KEY (`id_limitador`),
            UNIQUE KEY `id_product` (`id_product`)
        ) ENGINE=' . _MYSQL_ENGINE_ . ' DEFAULT CHARSET=utf8;';

        foreach ($sql as $query) {
            if (Db::getInstance()->execute($query) == false) {
                return false;
            }
        }

        return true;
    }

    protected function deleteTables()
    {
        $sql = 'DROP TABLE IF EXISTS `' . _DB_PREFIX_ . 'limitador_unidades`';
        return Db::getInstance()->execute($sql);
    }

    protected function installConfiguration()
    {
        return Configuration::updateValue('LIMITADOR_UNIDADES_ACTIVE', 1)
            && Configuration::updateValue('LIMITADOR_UNIDADES_MESSAGE', 'No se venden más de {limit} unidades. Si quieres más, debes hacer varios pedidos.');
    }

    protected function deleteConfiguration()
    {
        return Configuration::deleteByName('LIMITADOR_UNIDADES_ACTIVE')
            && Configuration::deleteByName('LIMITADOR_UNIDADES_MESSAGE');
    }

    public function getContent()
    {
        $output = null;

        if (Tools::isSubmit('submitLimitadorUnidadesConfig')) {
            $this->_postValidation();
            if (!count($this->_errors)) {
                $this->_postProcess();
                $output .= $this->displayConfirmation($this->l('Configuración actualizada'));
            } else {
                foreach ($this->_errors as $err) {
                    $output .= $this->displayError($err);
                }
            }
        }

        if (Tools::isSubmit('submitAddProductLimit')) {
            $this->_processAddProductLimit();
            if (!count($this->_errors)) {
                $output .= $this->displayConfirmation($this->l('Límite de producto agregado correctamente'));
            } else {
                foreach ($this->_errors as $err) {
                    $output .= $this->displayError($err);
                }
            }
        }

        if (Tools::isSubmit('deleteProductLimit')) {
            $this->_processDeleteProductLimit();
            $output .= $this->displayConfirmation($this->l('Límite de producto eliminado'));
        }

        return $output . $this->_displayForm();
    }

    private function _postValidation()
    {
        if (Tools::isSubmit('submitLimitadorUnidadesConfig')) {
            if (!Tools::getValue('LIMITADOR_UNIDADES_MESSAGE') || empty(Tools::getValue('LIMITADOR_UNIDADES_MESSAGE'))) {
                $this->_errors[] = $this->l('El mensaje de límite es requerido');
            }
        }
    }

    private function _postProcess()
    {
        if (Tools::isSubmit('submitLimitadorUnidadesConfig')) {
            Configuration::updateValue('LIMITADOR_UNIDADES_ACTIVE', (int)Tools::getValue('LIMITADOR_UNIDADES_ACTIVE'));
            Configuration::updateValue('LIMITADOR_UNIDADES_MESSAGE', pSQL(Tools::getValue('LIMITADOR_UNIDADES_MESSAGE')));
        }
    }

    private function _processAddProductLimit()
    {
        $id_product = (int)Tools::getValue('id_product');
        $max_units = (int)Tools::getValue('max_units');

        if (!$id_product) {
            $this->_errors[] = $this->l('Debe seleccionar un producto válido');
            return;
        }

        if ($max_units <= 0) {
            $this->_errors[] = $this->l('El límite de unidades debe ser mayor a 0');
            return;
        }

        if (!Product::existsInDatabase($id_product, 'product')) {
            $this->_errors[] = $this->l('El producto seleccionado no existe');
            return;
        }

        $existing = Db::getInstance()->getRow('
            SELECT id_limitador FROM ' . _DB_PREFIX_ . 'limitador_unidades 
            WHERE id_product = ' . (int)$id_product
        );

        if ($existing) {
            $result = Db::getInstance()->update('limitador_unidades', array(
                'max_units' => (int)$max_units,
                'active' => 1,
                'date_upd' => date('Y-m-d H:i:s')
            ), 'id_product = ' . (int)$id_product);
        } else {
            $result = Db::getInstance()->insert('limitador_unidades', array(
                'id_product' => (int)$id_product,
                'max_units' => (int)$max_units,
                'active' => 1,
                'date_add' => date('Y-m-d H:i:s'),
                'date_upd' => date('Y-m-d H:i:s')
            ));
        }

        if (!$result) {
            $this->_errors[] = $this->l('Error al guardar el límite del producto');
        }
    }

    private function _processDeleteProductLimit()
    {
        $id_limitador = (int)Tools::getValue('id_limitador');
        if ($id_limitador) {
            Db::getInstance()->delete('limitador_unidades', 'id_limitador = ' . (int)$id_limitador);
        }
    }

    private function _displayForm()
    {
        $products_with_limits = $this->getProductsWithLimits();
        
        $this->context->smarty->assign(array(
            'module_dir' => $this->_path,
            'limitador_active' => Configuration::get('LIMITADOR_UNIDADES_ACTIVE'),
            'limitador_message' => Configuration::get('LIMITADOR_UNIDADES_MESSAGE'),
            'products_with_limits' => $products_with_limits,
        ));

        return $this->display(__FILE__, 'views/templates/admin/configure.tpl');
    }

    private function getProductsWithLimits()
    {
        $sql = 'SELECT l.*, pl.name as product_name, p.reference
                FROM ' . _DB_PREFIX_ . 'limitador_unidades l
                LEFT JOIN ' . _DB_PREFIX_ . 'product p ON l.id_product = p.id_product
                LEFT JOIN ' . _DB_PREFIX_ . 'product_lang pl ON (l.id_product = pl.id_product AND pl.id_lang = ' . (int)$this->context->language->id . ')
                ORDER BY l.date_add DESC';

        return Db::getInstance()->executeS($sql);
    }

    public function hookDisplayHeader($params)
    {
        if (!Configuration::get('LIMITADOR_UNIDADES_ACTIVE')) {
            return '';
        }

        // Mostrar error si viene de redirección
        if (Tools::getValue('limitador_error')) {
            $error_message = Tools::getValue('limitador_error');
            
            return '<script>
                $(document).ready(function() {
                    alert("¡LÍMITE ALCANZADO!\\n' . addslashes($error_message) . '");
                    // Recargar la página para mostrar el estado correcto del carrito
                    setTimeout(function() {
                        window.location.reload();
                    }, 1000);
                });
            </script>';
        }

        return '';
    }

    public function hookDisplayProductAdditionalInfo($params)
    {
        if (!Configuration::get('LIMITADOR_UNIDADES_ACTIVE')) {
            return '';
        }

        $id_product = (int)$params['product']['id_product'];
        $limit = $this->getProductLimit($id_product);
        $current_quantity = $this->getCurrentCartQuantity($id_product);

        if ($limit && $limit > 0) {
            $message = str_replace('{limit}', $limit, Configuration::get('LIMITADOR_UNIDADES_MESSAGE'));
            
            $this->context->smarty->assign(array(
                'limit_message' => $message,
                'product_limit' => $limit,
                'current_quantity' => $current_quantity,
                'limit_reached' => ($current_quantity >= $limit),
                'remaining_units' => max(0, $limit - $current_quantity),
                'id_product' => $id_product
            ));

            return $this->display(__FILE__, 'views/templates/hook/product.tpl');
        }

        return '';
    }

    public function hookActionCartSave($params)
    {
        if (!Configuration::get('LIMITADOR_UNIDADES_ACTIVE')) {
            return;
        }

        try {
            $cart = $params['cart'];
            $products = $cart->getProducts();
            $cart_modified = false;

            foreach ($products as $product) {
                $limit = $this->getProductLimit($product['id_product']);
                if ($limit > 0 && $product['cart_quantity'] > $limit) {
                    // FORZAR la cantidad al límite SIEMPRE
                    $cart->updateQty($limit, $product['id_product'], $product['id_product_attribute']);
                    $cart_modified = true;
                }
            }

            // Si se modificó, guardar inmediatamente
            if ($cart_modified) {
                $cart->save();
            }
        } catch (Exception $e) {
            // Si hay error, no hacer nada para evitar romper la página
        }
    }

    public function hookDisplayBeforeBodyClosingTag($params)
    {
        if (!Configuration::get('LIMITADOR_UNIDADES_ACTIVE')) {
            return '';
        }

        // Solo JavaScript básico para deshabilitar visualmente
        $current_product_id = 0;
        $current_product_limit = 0;
        $current_product_quantity = 0;
        
        try {
            if ($this->context->controller instanceof ProductController) {
                $current_product_id = (int)Tools::getValue('id_product');
                $current_product_limit = $this->getProductLimit($current_product_id);
                $current_product_quantity = $this->getCurrentCartQuantity($current_product_id);
            }
        } catch (Exception $e) {
            // Si hay error, usar valores por defecto
        }

        $limit_reached = ($current_product_quantity >= $current_product_limit && $current_product_limit > 0);

        if ($limit_reached) {
            return '<script>
                $(document).ready(function() {
                    console.log("Límite alcanzado para producto ' . $current_product_id . '");
                    
                    // Deshabilitar visualmente botones (solo visual)
                    $("button, input[type=submit]").each(function() {
                        var text = $(this).text().toLowerCase();
                        if (text.indexOf("añadir") !== -1 || text.indexOf("agregar") !== -1 || text.indexOf("add") !== -1) {
                            $(this).css({
                                "opacity": "0.5",
                                "cursor": "not-allowed"
                            }).attr("title", "Límite alcanzado");
                        }
                    });
                    
                    // Mostrar mensaje permanente
                    if (!$("#limitador-warning").length) {
                        $(".product-add-to-cart, .add-to-cart").first().prepend(
                            "<div id=\"limitador-warning\" style=\"background: #f8d7da; border: 2px solid #f5c6cb; color: #721c24; padding: 15px; margin: 15px 0; border-radius: 5px; font-weight: bold; text-align: center;\">" +
                            "<i class=\"icon-warning\"></i> ¡LÍMITE ALCANZADO!<br>" +
                            "Ya tienes el máximo permitido (' . $current_product_limit . ' unidades) de este producto.<br>" +
                            "<small>Las peticiones adicionales serán automáticamente limitadas.</small>" +
                            "</div>"
                        );
                    }
                });
            </script>';
        }

        return '';
    }

    private function getCurrentCartQuantity($id_product)
    {
        try {
            if (!$this->context->cart) {
                return 0;
            }

            $products = $this->context->cart->getProducts();
            foreach ($products as $product) {
                if ($product['id_product'] == $id_product) {
                    return (int)$product['cart_quantity'];
                }
            }
        } catch (Exception $e) {
            // Si hay error, devolver 0
        }
        
        return 0;
    }

    private function getProductLimit($id_product)
    {
        try {
            $result = Db::getInstance()->getRow('
                SELECT max_units FROM ' . _DB_PREFIX_ . 'limitador_unidades 
                WHERE id_product = ' . (int)$id_product . ' AND active = 1'
            );

            return $result ? (int)$result['max_units'] : 0;
        } catch (Exception $e) {
            return 0;
        }
    }

    public function ajaxProcessSearchProducts()
    {
        header('Content-Type: application/json');
        
        $query = Tools::getValue('q');
        $products = array();

        if (strlen($query) >= 2) {
            $sql = 'SELECT p.id_product, pl.name, p.reference
                    FROM ' . _DB_PREFIX_ . 'product p
                    LEFT JOIN ' . _DB_PREFIX_ . 'product_lang pl ON (p.id_product = pl.id_product AND pl.id_lang = ' . (int)Context::getContext()->language->id . ')
                    WHERE p.active = 1 AND (
                        pl.name LIKE "%' . pSQL($query) . '%"
                        OR p.reference LIKE "%' . pSQL($query) . '%"
                        OR p.id_product = ' . (int)$query . '
                    )
                    ORDER BY pl.name
                    LIMIT 20';

            $results = Db::getInstance()->executeS($sql);
            
            if ($results) {
                foreach ($results as $result) {
                    $text = $result['name'];
                    if ($result['reference']) {
                        $text .= ' (Ref: ' . $result['reference'] . ')';
                    }
                    $text .= ' [ID: ' . $result['id_product'] . ']';
                    
                    $products[] = array(
                        'id' => $result['id_product'],
                        'text' => $text
                    );
                }
            }
        }

        echo json_encode($products);
        exit;
    }
}