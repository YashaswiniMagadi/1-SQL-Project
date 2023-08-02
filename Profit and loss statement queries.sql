-- 1. Creation gross price view

CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `gross_price` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`fiscal_year` AS `fiscal_year`,
        `s`.`customer_code` AS `customer_code`,
        `c`.`customer` AS `customer`,
        `c`.`market` AS `market`,
        `s`.`product_code` AS `product_code`,
        `p`.`product` AS `product`,
        `p`.`variant` AS `variant`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `g`.`gross_price` AS `gross_price`,
        ROUND((`s`.`sold_quantity` * `g`.`gross_price`),
                2) AS `total_gross_price`
    FROM
        ((((`fact_sales_monthly` `s`
        JOIN `dim_product` `p` ON ((`p`.`product_code` = `s`.`product_code`)))
        JOIN `fact_gross_price` `g` ON (((`g`.`product_code` = `s`.`product_code`)
            AND (`g`.`fiscal_year` = `s`.`fiscal_year`))))
        JOIN `dim_customer` `c` ON ((`s`.`customer_code` = `c`.`customer_code`)))
        JOIN `fact_pre_invoice_deductions` `pre` ON (((`pre`.`customer_code` = `s`.`customer_code`)
            AND (`pre`.`fiscal_year` = `s`.`fiscal_year`)
            AND (`s`.`fiscal_year` = `g`.`fiscal_year`))))
            
-- 2. Creation of sales_postinvice and sales_preinvoice deductions

CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `sales_postinv_discount` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`fiscal_year` AS `fiscal_year`,
        `s`.`customer_code` AS `customer_code`,
        `s`.`market` AS `market`,
        `s`.`product_code` AS `product_code`,
        `s`.`product` AS `product`,
        `s`.`variant` AS `variant`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `s`.`total_gross_price` AS `total_gross_price`,
        `s`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`,
        ((1 - `s`.`pre_invoice_discount_pct`) * `s`.`total_gross_price`) AS `net_invoice_sales`,
        (`po`.`discounts_pct` + `po`.`other_deductions_pct`) AS `post_invoice_discount_pct`
    FROM
        (`sales_preinv_deductions` `s`
        JOIN `fact_post_invoice_deductions` `po` ON (((`po`.`customer_code` = `s`.`customer_code`)
            AND (`po`.`product_code` = `s`.`product_code`)
            AND (`po`.`date` = `s`.`date`))))
            
            
--

CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `sales_preinv_deductions` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`customer_code` AS `customer_code`,
        `s`.`fiscal_year` AS `fiscal_year`,
        `s`.`product_code` AS `product_code`,
        `p`.`product` AS `product`,
        `p`.`variant` AS `variant`,
        `c`.`market` AS `market`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `g`.`gross_price` AS `gross_price`,
        ROUND((`s`.`sold_quantity` * `g`.`gross_price`),
                2) AS `total_gross_price`,
        `pre`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`
    FROM
        ((((`fact_sales_monthly` `s`
        JOIN `dim_customer` `c` ON ((`s`.`customer_code` = `c`.`customer_code`)))
        JOIN `dim_product` `p` ON ((`p`.`product_code` = `s`.`product_code`)))
        JOIN `fact_gross_price` `g` ON (((`g`.`product_code` = `s`.`product_code`)
            AND (`g`.`fiscal_year` = `s`.`fiscal_year`))))
        JOIN `fact_pre_invoice_deductions` `pre` ON (((`pre`.`customer_code` = `s`.`customer_code`)
            AND (`pre`.`fiscal_year` = `s`.`fiscal_year`)
            AND (`s`.`fiscal_year` = `g`.`fiscal_year`))))
            
            
-- 3. Creation of net sales view

CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `net_sales` AS
    SELECT 
        `sales_postinv_discount`.`date` AS `date`,
        `sales_postinv_discount`.`fiscal_year` AS `fiscal_year`,
        `sales_postinv_discount`.`customer_code` AS `customer_code`,
        `sales_postinv_discount`.`market` AS `market`,
        `sales_postinv_discount`.`product_code` AS `product_code`,
        `sales_postinv_discount`.`product` AS `product`,
        `sales_postinv_discount`.`variant` AS `variant`,
        `sales_postinv_discount`.`sold_quantity` AS `sold_quantity`,
        `sales_postinv_discount`.`total_gross_price` AS `total_gross_price`,
        `sales_postinv_discount`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`,
        `sales_postinv_discount`.`net_invoice_sales` AS `net_invoice_sales`,
        `sales_postinv_discount`.`post_invoice_discount_pct` AS `post_invoice_discount_pct`,
        (`sales_postinv_discount`.`net_invoice_sales` * (1 - `sales_postinv_discount`.`post_invoice_discount_pct`)) AS `net_sales`
    FROM
        `sales_postinv_discount`