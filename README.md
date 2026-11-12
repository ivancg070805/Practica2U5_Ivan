# Práctica 2 U5 — Base de Datos de un Almacén (MySQL)

Proyecto de práctica para la creación de una base de datos relacional de un **almacén (warehouse)** en **MySQL 8.0**, con sus tablas relacionadas mediante claves foráneas y datos de ejemplo (mínimo 10 registros por tabla).

**Autor:** [ivancg070805](https://github.com/ivancg070805)

---

## 📁 Contenido del repositorio

| Archivo | Descripción |
|---|---|
| `almacen_mysql.sql` | Script completo: creación de la base de datos, 9 tablas relacionadas, índices y datos de ejemplo |

---

## 🏗️ Modelo de datos

La base de datos se llama `almacen` y está formada por **9 tablas relacionadas**:

```
proveedores ──┐
              ├──> productos <──┬── categorias
              │                 └── ubicaciones
              │
  ordenes_entrada                 ordenes_salida
        │                              │
        └──> detalle_entrada           └──> detalle_salida
                    │                              │
                    └──────────> productos <───────┘
                                        ▲
                                     clientes
```

### Tablas y registros

| # | Tabla | Registros | Descripción |
|---|---|---|---|
| 1 | `proveedores` | 10 | Proveedores de mercancía |
| 2 | `categorias` | 10 | Clasificación de productos |
| 3 | `ubicaciones` | 10 | Ubicación física (pasillo / estante / nivel) |
| 4 | `productos` | 10 | Productos con SKU, precios y stock mínimo |
| 5 | `clientes` | 10 | Clientes del almacén |
| 6 | `ordenes_entrada` | 10 | Recepciones de mercancía |
| 7 | `ordenes_salida` | 10 | Ventas / envíos a clientes |
| 8 | `detalle_entrada` | 12 | Líneas de cada recepción |
| 9 | `detalle_salida` | 12 | Líneas de cada venta / envío |

### Relaciones (claves foráneas)

| Tabla hija | Columna | Tabla padre |
|---|---|---|
| `productos` | `categoria_id` | `categorias.id` |
| `productos` | `proveedor_id` | `proveedores.id` |
| `productos` | `ubicacion_id` | `ubicaciones.id` |
| `ordenes_entrada` | `proveedor_id` | `proveedores.id` |
| `ordenes_salida` | `cliente_id` | `clientes.id` |
| `detalle_entrada` | `orden_entrada_id` | `ordenes_entrada.id` (ON DELETE CASCADE) |
| `detalle_entrada` | `producto_id` | `productos.id` |
| `detalle_salida` | `orden_salida_id` | `ordenes_salida.id` (ON DELETE CASCADE) |
| `detalle_salida` | `producto_id` | `productos.id` |

### Características técnicas

- Motor **InnoDB** con claves foráneas nombradas (`fk_...`)
- `ENUM` para estados (`pendiente`, `recibida/entregada`, `cancelada`)
- Restricciones `CHECK` para precios y cantidades positivas
- Índices en todas las columnas de claves foráneas
- Charset `utf8mb4` / colación `utf8mb4_spanish_ci`

---

## 🚀 Cómo ejecutar el script

### Opción A — MySQL Workbench

1. Abre MySQL Workbench y conéctate a tu servidor MySQL.
2. Ve a `File → Open SQL Script` y selecciona `almacen_mysql.sql`.
3. Ejecuta todo el script con el botón ⚡ o `Ctrl + Shift + Enter`.

### Opción B — Terminal

```bash
mysql -u root -p < almacen_mysql.sql
```

> El script crea la base de datos `almacen` (la elimina si ya existe) y ejecuta al final dos consultas de verificación: conteo de registros y un `JOIN` de productos con su categoría, proveedor y ubicación.

---

## ✅ Verificación rápida

```sql
USE almacen;
SELECT COUNT(*) FROM productos;   -- 10
SELECT COUNT(*) FROM clientes;    -- 10
```

Consulta de productos con sus relaciones:

```sql
SELECT p.sku, p.nombre AS producto, c.nombre AS categoria,
       pr.nombre AS proveedor,
       CONCAT('Pasillo ', u.pasillo, ' / Estante ', u.estante, ' / Nivel ', u.nivel) AS ubicacion
FROM productos p
JOIN categorias c  ON c.id  = p.categoria_id
JOIN proveedores pr ON pr.id = p.proveedor_id
JOIN ubicaciones u ON u.id  = p.ubicacion_id
ORDER BY p.id;
```

---

## 📋 Requisitos

- MySQL Server **8.0** o superior (compatible con 5.7 en su mayoría)
- Cliente MySQL o MySQL Workbench

---

## 📄 Licencia

Proyecto académico de uso libre.
