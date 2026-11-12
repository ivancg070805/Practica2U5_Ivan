-- =========================================================
-- BASE DE DATOS: ALMACÉN (Warehouse) para MySQL 8.0
-- Tablas relacionadas con claves foráneas (FK)
-- Mínimo 10 registros por tabla
-- Ejecutar con: mysql -u root -p < almacen_mysql.sql
-- O pegarlo en MySQL Workbench y dar "Run"
-- =========================================================

DROP DATABASE IF EXISTS almacen;
CREATE DATABASE almacen CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;
USE almacen;

-- =========================================================
-- 1. PROVEEDORES: de quién compramos mercancía
-- =========================================================
CREATE TABLE proveedores (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(100) NOT NULL,
  contacto     VARCHAR(100),
  telefono     VARCHAR(20),
  email        VARCHAR(100),
  ciudad       VARCHAR(50),
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =========================================================
-- 2. CATEGORIAS: clasificación de los productos
-- =========================================================
CREATE TABLE categorias (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(60) NOT NULL UNIQUE,
  descripcion  VARCHAR(200)
) ENGINE=InnoDB;

-- =========================================================
-- 3. UBICACIONES: pasillo/estante dentro del almacén
-- =========================================================
CREATE TABLE ubicaciones (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  pasillo      VARCHAR(10) NOT NULL,
  estante      VARCHAR(10) NOT NULL,
  nivel        INT NOT NULL,
  UNIQUE KEY uq_ubicacion (pasillo, estante, nivel)
) ENGINE=InnoDB;

-- =========================================================
-- 4. PRODUCTOS: artículo que se guarda en el almacén
--    FK: categoria_id, proveedor_id, ubicacion_id
-- =========================================================
CREATE TABLE productos (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  sku           VARCHAR(30) NOT NULL UNIQUE,
  nombre        VARCHAR(100) NOT NULL,
  descripcion   VARCHAR(200),
  categoria_id  INT NOT NULL,
  proveedor_id  INT NOT NULL,
  ubicacion_id  INT NOT NULL,
  precio_costo  DECIMAL(10,2) NOT NULL,
  precio_venta  DECIMAL(10,2) NOT NULL,
  stock_minimo  INT NOT NULL DEFAULT 5,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id),
  CONSTRAINT fk_producto_proveedor FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
  CONSTRAINT fk_producto_ubicacion FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(id),
  CONSTRAINT chk_precios CHECK (precio_costo >= 0 AND precio_venta >= 0)
) ENGINE=InnoDB;

-- =========================================================
-- 5. CLIENTES: a quién vendemos
-- =========================================================
CREATE TABLE clientes (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(100) NOT NULL,
  rfc          VARCHAR(13) UNIQUE,
  telefono     VARCHAR(20),
  email        VARCHAR(100),
  ciudad       VARCHAR(50),
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =========================================================
-- 6. ORDENES_ENTRADA: recepciones de mercancía del proveedor
--    FK: proveedor_id -> proveedores
-- =========================================================
CREATE TABLE ordenes_entrada (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  proveedor_id   INT NOT NULL,
  folio          VARCHAR(30) NOT NULL UNIQUE,
  fecha_entrada  DATE NOT NULL,
  estado         ENUM('pendiente','recibida','cancelada') NOT NULL DEFAULT 'recibida',
  total          DECIMAL(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_entrada_proveedor FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
) ENGINE=InnoDB;

-- =========================================================
-- 7. ORDENES_SALIDA: ventas/envíos a clientes
--    FK: cliente_id -> clientes
-- =========================================================
CREATE TABLE ordenes_salida (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  cliente_id     INT NOT NULL,
  folio          VARCHAR(30) NOT NULL UNIQUE,
  fecha_salida   DATE NOT NULL,
  estado         ENUM('pendiente','entregada','cancelada') NOT NULL DEFAULT 'entregada',
  total          DECIMAL(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_salida_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) ENGINE=InnoDB;

-- =========================================================
-- 8. DETALLE_ENTRADA: líneas de cada recepción
--    FK: orden_entrada_id -> ordenes_entrada, producto_id -> productos
-- =========================================================
CREATE TABLE detalle_entrada (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  orden_entrada_id INT NOT NULL,
  producto_id      INT NOT NULL,
  cantidad         INT NOT NULL,
  precio_unitario  DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_dent_orden FOREIGN KEY (orden_entrada_id) REFERENCES ordenes_entrada(id) ON DELETE CASCADE,
  CONSTRAINT fk_dent_producto FOREIGN KEY (producto_id) REFERENCES productos(id),
  CONSTRAINT chk_dent_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

-- =========================================================
-- 9. DETALLE_SALIDA: líneas de cada venta/envío
--    FK: orden_salida_id -> ordenes_salida, producto_id -> productos
-- =========================================================
CREATE TABLE detalle_salida (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  orden_salida_id INT NOT NULL,
  producto_id     INT NOT NULL,
  cantidad        INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_dsal_orden FOREIGN KEY (orden_salida_id) REFERENCES ordenes_salida(id) ON DELETE CASCADE,
  CONSTRAINT fk_dsal_producto FOREIGN KEY (producto_id) REFERENCES productos(id),
  CONSTRAINT chk_dsal_cantidad CHECK (cantidad > 0)
) ENGINE=InnoDB;

-- Índices para acelerar consultas frecuentes
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_productos_proveedor ON productos(proveedor_id);
CREATE INDEX idx_productos_ubicacion ON productos(ubicacion_id);
CREATE INDEX idx_dentrada_orden ON detalle_entrada(orden_entrada_id);
CREATE INDEX idx_dentrada_producto ON detalle_entrada(producto_id);
CREATE INDEX idx_dsalida_orden ON detalle_salida(orden_salida_id);
CREATE INDEX idx_dsalida_producto ON detalle_salida(producto_id);

-- =========================================================
-- DATOS DE PRUEBA (mínimo 10 registros por tabla)
-- =========================================================

INSERT INTO proveedores (nombre, contacto, telefono, email, ciudad) VALUES
('Distribuidora del Norte', 'Luis Ramírez', '81-1234-5601', 'ventas@distnorte.mx', 'Monterrey'),
('Tornillos y Herrajes SA', 'María López', '55-2345-6702', 'contacto@tyh.com.mx', 'CDMX'),
('Papeles Comerciales', 'Jorge Chávez', '33-3456-7803', 'jorge.chavez@papcom.mx', 'Guadalajara'),
('Plásticos Industriales MX', 'Ana Torres', '81-4567-8904', 'atorres@plastimx.com', 'Monterrey'),
('Química del Bajío', 'Pedro Sánchez', '477-567-8905', 'psanchez@quimicabajio.mx', 'León'),
('Electrónica Central', 'Laura Méndez', '55-6789-0116', 'lmendez@eleccentral.mx', 'CDMX'),
('Empaques Modernos', 'Carlos Ruiz', '222-789-0127', 'cruiz@empaquesmod.com', 'Puebla'),
('Ferretería del Valle', 'Sofía Herrera', '664-890-1238', 'sherrera@ferrvalle.mx', 'Tijuana'),
('Limpieza Profesional SA', 'Diego Fernández', '55-901-2349', 'dfdez@limpzapmx.com', 'CDMX'),
('Oficinas y Máquinas', 'Elena Castro', '33-012-3450', 'ecastroy@ofimaq.mx', 'Guadalajara');

INSERT INTO categorias (nombre, descripcion) VALUES
('Herramientas', 'Herramientas manuales y eléctricas'),
('Tornillería', 'Tornillos, tuercas y clavos'),
('Papelería', 'Papel, sobres y útiles de oficina'),
('Plásticos', 'Contenedores, bolsas y utensilios de plástico'),
('Químicos', 'Limpiadores, solventes y lubricantes'),
('Electrónica', 'Cables, conectores y componentes'),
('Empaques', 'Cajas, cintas y material de empaque'),
('Ferretería', 'Candados, bisagras y cierres'),
('Limpieza', 'Implementos de limpieza industrial'),
('Oficina', 'Máquinas y mobiliario de oficina');

INSERT INTO ubicaciones (pasillo, estante, nivel) VALUES
('A', '1', 1), ('A', '1', 2), ('A', '2', 1),
('B', '1', 1), ('B', '1', 2), ('B', '2', 1),
('C', '1', 1), ('C', '1', 2), ('C', '2', 1),
('D', '1', 1);

INSERT INTO productos (sku, nombre, descripcion, categoria_id, proveedor_id, ubicacion_id, precio_costo, precio_venta, stock_minimo) VALUES
('SKU-1001', 'Martillo de garra 16 oz', 'Mango de fibra de vidrio', 1, 1, 1, 95.00, 149.00, 10),
('SKU-1002', 'Desarmador plano 6mm', 'Acero cromado', 1, 2, 2, 28.50, 45.00, 20),
('SKU-1003', 'Tornillo madera 1 pulg (caja 500pzs)', 'Acero zincado', 2, 2, 3, 180.00, 240.00, 5),
('SKU-1004', 'Resma carta 75g', 'Papel blanco', 3, 3, 4, 85.00, 120.00, 15),
('SKU-1005', 'Contenedor plástico 20L', 'Polietileno alto impacto', 4, 4, 5, 110.00, 165.00, 8),
('SKU-1006', 'Limpiador multiusos 5L', 'Uso industrial', 5, 5, 6, 65.00, 98.00, 12),
('SKU-1007', 'Cable eléctrico cal. 14 (rollo 100m)', 'Cobre THW', 6, 6, 7, 420.00, 560.00, 4),
('SKU-1008', 'Caja cartón 40x30x20 (paq. 25)', 'Corrugado simple', 7, 7, 8, 350.00, 480.00, 6),
('SKU-1009', 'Candado de latón 50mm', '3 llaves incluidas', 8, 8, 9, 70.00, 110.00, 15),
('SKU-1010', 'Escoba industrial', 'Fibra rígida', 9, 9, 10, 48.00, 75.00, 20);

INSERT INTO clientes (nombre, rfc, telefono, email, ciudad) VALUES
('Constructora Altavista', 'CAA880101AAA', '55-1111-0001', 'compras@altavista.mx', 'CDMX'),
('Ferretería El Tornillo Feliz', 'FET990202BBB', '55-2222-0002', 'ventas@tornillofeliz.mx', 'CDMX'),
('Oficinas Gómez y Asociados', 'OGA001031CCC', '33-3333-0003', 'compras@gomezasoc.com', 'Guadalajara'),
('Escuelas del Valle', 'EDV770104DDD', '81-4444-0004', 'admon@escuelasvalle.mx', 'Monterrey'),
('Hoteles Pacifico Sur', 'HPS880105EEE', '322-555-0005', 'mantto@hotelpacifico.mx', 'Puerto Vallarta'),
('Limpiezas Rotha SA', 'LRO990106FFF', '55-6666-0006', 'info@limpiezaasrotha.com', 'CDMX'),
('Talleres Mecánicos Vera', 'TMV000107GGG', '477-777-0007', 'refacciones@tvera.mx', 'León'),
('Constructora Costa Norte', 'CCN880108HHH', '664-888-0008', 'compras@costanorte.com', 'Tijuana'),
('Papelería La Pluma', 'PLP990109III', '222-999-0009', 'lapluma@papelmx.com', 'Puebla'),
('Restaurantes Don José', 'RDJ000110JJJ', '998-111-0010', 'admin@donjose.mx', 'Cancún');

INSERT INTO ordenes_entrada (proveedor_id, folio, fecha_entrada, estado, total) VALUES
(1, 'OE-2026-001', '2026-09-15', 'recibida', 2850.00),
(2, 'OE-2026-002', '2026-09-18', 'recibida', 1640.00),
(3, 'OE-2026-003', '2026-09-22', 'recibida', 1275.00),
(4, 'OE-2026-004', '2026-09-25', 'recibida', 1320.00),
(5, 'OE-2026-005', '2026-10-01', 'recibida', 975.00),
(6, 'OE-2026-006', '2026-10-03', 'recibida', 1680.00),
(7, 'OE-2026-007', '2026-10-06', 'recibida', 1400.00),
(8, 'OE-2026-008', '2026-10-09', 'recibida', 1050.00),
(9, 'OE-2026-009', '2026-10-12', 'pendiente', 890.00),
(10, 'OE-2026-010', '2026-10-15', 'recibida', 2300.00);

INSERT INTO ordenes_salida (cliente_id, folio, fecha_salida, estado, total) VALUES
(1, 'OS-2026-001', '2026-09-20', 'entregada', 2980.00),
(2, 'OS-2026-002', '2026-09-24', 'entregada', 1620.00),
(3, 'OS-2026-003', '2026-09-28', 'entregada', 1150.00),
(4, 'OS-2026-004', '2026-10-02', 'entregada', 890.00),
(5, 'OS-2026-005', '2026-10-05', 'entregada', 1340.00),
(6, 'OS-2026-006', '2026-10-08', 'entregada', 760.00),
(7, 'OS-2026-007', '2026-10-11', 'entregada', 2450.00),
(8, 'OS-2026-008', '2026-10-14', 'entregada', 1890.00),
(9, 'OS-2026-009', '2026-10-17', 'entregada', 620.00),
(10, 'OS-2026-010', '2026-10-20', 'pendiente', 1120.00);

INSERT INTO detalle_entrada (orden_entrada_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 20, 95.00),
(2, 2, 40, 28.50),
(2, 3, 6, 180.00),
(3, 4, 15, 85.00),
(4, 5, 12, 110.00),
(5, 6, 15, 65.00),
(6, 7, 4, 420.00),
(7, 8, 4, 350.00),
(8, 9, 15, 70.00),
(9, 10, 18, 48.00),
(10, 4, 10, 85.00),
(10, 6, 8, 65.00);

INSERT INTO detalle_salida (orden_salida_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 10, 149.00),
(1, 7, 1, 560.00),
(2, 2, 12, 45.00),
(2, 3, 3, 240.00),
(3, 4, 8, 120.00),
(4, 10, 8, 75.00),
(5, 6, 12, 98.00),
(5, 5, 3, 165.00),
(6, 9, 5, 110.00),
(7, 7, 2, 560.00),
(8, 3, 3, 240.00),
(9, 4, 5, 120.00);

-- =========================================================
-- VERIFICACIÓN: consultar las relaciones
-- =========================================================
SELECT 'proveedores' AS tabla, COUNT(*) AS registros FROM proveedores
UNION ALL SELECT 'categorias', COUNT(*) FROM categorias
UNION ALL SELECT 'ubicaciones', COUNT(*) FROM ubicaciones
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'ordenes_entrada', COUNT(*) FROM ordenes_entrada
UNION ALL SELECT 'ordenes_salida', COUNT(*) FROM ordenes_salida
UNION ALL SELECT 'detalle_entrada', COUNT(*) FROM detalle_entrada
UNION ALL SELECT 'detalle_salida', COUNT(*) FROM detalle_salida;

-- Productos con su categoría, proveedor y ubicación (JOIN)
SELECT p.sku, p.nombre AS producto, c.nombre AS categoria,
       pr.nombre AS proveedor,
       CONCAT('Pasillo ', u.pasillo, ' / Estante ', u.estante, ' / Nivel ', u.nivel) AS ubicacion
FROM productos p
JOIN categorias c ON c.id = p.categoria_id
JOIN proveedores pr ON pr.id = p.proveedor_id
JOIN ubicaciones u ON u.id = p.ubicacion_id
ORDER BY p.id;
