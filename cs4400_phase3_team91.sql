-- CS4400: Introduction to Database Systems (Fall 2024)
-- Project Phase III: Stored Procedures SHELL [v3] Thursday, Nov 7, 2024
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;


use business_supply;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [1] add_owner()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new owner.  A new owner must have a unique
username. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_owner;
delimiter //
create procedure add_owner (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date)
sp_main: begin
    -- ensure new owner has a unique username
    if exists (select 1 from users where username = ip_username) then
        leave sp_main;
    end if;

    insert into users (username, first_name, last_name, address, birthdate)
    values (ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);
    insert into business_owners (username) values (ip_username);
end //
delimiter ;


-- [2] add_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new employee without any designated driver or
worker roles.  A new employee must have a unique username and a unique tax identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_employee;
delimiter //
create procedure add_employee (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date,
    in ip_taxID varchar(40), in ip_hired date, in ip_employee_experience integer,
    in ip_salary integer)
sp_main: begin
    -- ensure new owner has a unique username
    -- ensure new employee has a unique tax identifier
    if exists (select 1 from users where username = ip_username) or
       exists (select 1 from employees where taxID = ip_taxID) then
        leave sp_main;
    end if;

    insert into users (username, first_name, last_name, address, birthdate)
    values (ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);
    insert into employees (username, taxID, hired, experience, salary)
    values (ip_username, ip_taxID, ip_hired, ip_employee_experience, ip_salary);
end //
delimiter ;

-- [3] add_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the driver role to an existing employee.  The
employee/new driver must have a unique license identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_driver_role;
delimiter //
create procedure add_driver_role (in ip_username varchar(40), in ip_licenseID varchar(40),
	in ip_license_type varchar(40), in ip_driver_experience integer)
sp_main: begin
    -- ensure employee exists and is not a worker
    -- ensure new driver has a unique license identifier
    if not exists (select 1 from employees where username = ip_username) or
       exists (select 1 from workers where username = ip_username) or
       exists (select 1 from drivers where licenseID = ip_licenseID) then
        leave sp_main;
    end if;

    insert into drivers (username, licenseID, license_type, successful_trips)
    values (ip_username, ip_licenseID, ip_license_type, ip_driver_experience);
end //
delimiter ;

-- [4] add_worker_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the worker role to an existing employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_worker_role;
delimiter //
create procedure add_worker_role (in ip_username varchar(40))
sp_main: begin
    -- ensure employee exists and is not a driver
    if not exists (select 1 from employees where username = ip_username) or
       exists (select 1 from drivers where username = ip_username) then
        leave sp_main;
    end if;

    insert into workers (username) values (ip_username);
end //
delimiter ;

-- [5] add_product()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new product.  A new product must have a
unique barcode. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_product;
delimiter //
create procedure add_product (in ip_barcode varchar(40), in ip_name varchar(100),
	in ip_weight integer)
sp_main: begin
	-- ensure new product doesn't already exist
    if exists (select 1 from products where barcode = ip_barcode) then
        leave sp_main;
    end if;

    insert into products (barcode, iname, weight) values (ip_barcode, ip_name, ip_weight);
end //
delimiter ;

-- [6] add_van()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new van.  A new van must be assigned 
to a valid delivery service and must have a unique tag.  Also, it must be driven
by a valid driver initially (i.e., driver works for the same service). And the van's starting
location will always be the delivery service's home base by default. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_van;
delimiter //
create procedure add_van (in ip_id varchar(40), in ip_tag integer, in ip_fuel integer,
	in ip_capacity integer, in ip_sales integer, in ip_driven_by varchar(40))
sp_main: begin
	-- ensure new van doesn't already exist
    -- ensure that the delivery service exists
    -- ensure that a valid driver will control the van
    
	declare check_tag_exists int default 0;
    declare check_service_exists int default 0;
    declare check_valid_driver int default 0;


    -- ensure the van tag is unique for the delivery service
    select count(*) into check_tag_exists from vans where id = ip_id and tag = ip_tag;

    -- ensure that the delivery service exists
    select count(*) into check_service_exists from delivery_services where id = ip_id;

    -- ensure the driver is valid and works for the specified delivery service
    select count(*) into check_valid_driver
    from drivers d
    where d.username = ip_driven_by;


    if check_tag_exists = 0 and check_service_exists > 0 and check_valid_driver > 0 then
	-- insert the new van into the vans table with the home base as the starting location
	insert into vans (id, tag, fuel, capacity, sales, driven_by, located_at)
	values (ip_id, ip_tag, ip_fuel, ip_capacity, ip_sales, ip_driven_by,
	(select home_base from delivery_services where id = ip_id));
end if;
end //
delimiter ;

-- [7] add_business()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new business.  A new business must have a
unique (long) name and must exist at a valid location, and have a valid rating.
And a resturant is initially "independent" (i.e., no owner), but will be assigned
an owner later for funding purposes. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_business;
delimiter //
create procedure add_business (in ip_long_name varchar(40), in ip_rating integer,
	in ip_spent integer, in ip_location varchar(40))
sp_main: begin
	-- ensure new business doesn't already exist
    -- ensure that the location is valid
    -- ensure that the rating is valid (i.e., between 1 and 5 inclusively)
    if exists (select 1 from businesses where long_name = ip_long_name) or
       not exists (select 1 from locations where label = ip_location) or
       ip_rating < 1 or ip_rating > 5 then
        leave sp_main;
    end if;

    insert into businesses (long_name, rating, spent, location)
    values (ip_long_name, ip_rating, ip_spent, ip_location);
end //
delimiter ;

-- [8] add_service()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new delivery service.  A new service must have
a unique identifier, along with a valid home base and manager. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_service;
delimiter //
create procedure add_service (in ip_id varchar(40), in ip_long_name varchar(100),
	in ip_home_base varchar(40), in ip_manager varchar(40))
sp_main: begin
	-- ensure new delivery service doesn't already exist
    -- ensure that the home base location is valid
    -- ensure that the manager is valid
    if exists (select 1 from delivery_services where id = ip_id) or
       not exists (select 1 from locations where label = ip_home_base) or
       not exists (select 1 from workers where username = ip_manager) then
        leave sp_main;
    end if;

    insert into delivery_services (id, long_name, home_base, manager)
    values (ip_id, ip_long_name, ip_home_base, ip_manager);
end //
delimiter ;

-- [9] add_location()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new location that becomes a new valid van
destination.  A new location must have a unique combination of coordinates. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_location;
delimiter //
create procedure add_location (in ip_label varchar(40), in ip_x_coord integer,
	in ip_y_coord integer, in ip_space integer)
sp_main: begin
	-- ensure new location doesn't already exist
    -- ensure that the coordinate combination is distinct
	if exists (select 1 from locations where label = ip_label or (x_coord = ip_x_coord and y_coord = ip_y_coord)) then
        leave sp_main;
    end if;

    insert into locations (label, x_coord, y_coord, space)
    values (ip_label, ip_x_coord, ip_y_coord, ip_space);
end //
delimiter ;

-- [10] start_funding()
-- -----------------------------------------------------------------------------
/* This stored procedure opens a channel for a business owner to provide funds
to a business. The owner and business must be valid. */
-- -----------------------------------------------------------------------------
drop procedure if exists start_funding;
delimiter //
create procedure start_funding (in ip_owner varchar(40), in ip_amount integer, in ip_long_name varchar(40), in ip_fund_date date)
sp_main: begin
	-- ensure the owner and business are valid
    if not exists (select 1 from business_owners where username = ip_owner) or
       not exists (select 1 from businesses where long_name = ip_long_name) then
        leave sp_main;
    end if;

    insert into fund (username, invested, invested_date, business)
    values (ip_owner, ip_amount, ip_fund_date, ip_long_name);
end //
delimiter ;

-- [11] hire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure hires a worker to work for a delivery service.
If a worker is actively serving as manager for a different service, then they are
not eligible to be hired.  Otherwise, the hiring is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists hire_employee;
delimiter //
create procedure hire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee hasn't already been hired by that service
	-- ensure that the employee and delivery service are valid
    -- ensure that the employee isn't a manager for another service
    if exists (select 1 from work_for where username = ip_username and id = ip_id) or
       not exists (select 1 from employees where username = ip_username) or
       not exists (select 1 from delivery_services where id = ip_id) or
       exists (select 1 from delivery_services where manager = ip_username) then
        leave sp_main;
    end if;

    insert into work_for (username, id)
    values (ip_username, ip_id);
end //
delimiter ;

-- [12] fire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure fires a worker who is currently working for a delivery
service.  The only restriction is that the employee must not be serving as a manager 
for the service. Otherwise, the firing is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists fire_employee;
delimiter //
create procedure fire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee is currently working for the service
    -- ensure that the employee isn't an active manager
    if not exists (select 1 from work_for where username = ip_username and id = ip_id) or
       exists (select 1 from delivery_services where manager = ip_username and id = ip_id) then
        leave sp_main;
    end if;

    delete from work_for
    where username = ip_username and id = ip_id;
end //
delimiter ;

-- [13] manage_service()
-- -----------------------------------------------------------------------------
/* This stored procedure appoints a worker who is currently hired by a delivery
service as the new manager for that service.  The only restrictions is that
the worker must not be working for any other delivery service. Otherwise, the appointment 
to manager is permitted.  The current manager is simply replaced. */
-- -----------------------------------------------------------------------------
drop procedure if exists manage_service;
delimiter //
create procedure manage_service (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
	-- ensure that the employee is currently working for the service
    -- ensure that the employee isn't working for any other services
    if not exists (select 1 from work_for where username = ip_username and id = ip_id) or
       exists (select 1 from work_for where username = ip_username and id <> ip_id) then
        leave sp_main;
    end if;

    update delivery_services
    set manager = ip_username
    where id = ip_id;
end //
delimiter ;

-- [14] takeover_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a valid driver to take control of a van owned by 
the same delivery service. The current controller of the van is simply relieved 
of those duties. */
-- -----------------------------------------------------------------------------
drop procedure if exists takeover_van;
delimiter //
create procedure takeover_van (in ip_username varchar(40), in ip_id varchar(40),
	in ip_tag integer)
sp_main: begin
	-- ensure that the driver is not driving for another service
	-- ensure that the selected van is owned by the same service
    -- ensure that the employee is a valid driver
    if exists (select 1 from vans where driven_by = ip_username and id <> ip_id) or
       not exists (select 1 from vans where id = ip_id and tag = ip_tag) or
       not exists (select 1 from drivers where username = ip_username) then
        leave sp_main;
    end if;

    update vans
    set driven_by = ip_username
    where id = ip_id and tag = ip_tag;
end //
delimiter ;

-- [15] load_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add some quantity of fixed-size packages of
a specific product to a van's payload so that we can sell them for some
specific price to other businesses.  The van can only be loaded if it's located
at its delivery service's home base, and the van must have enough capacity to
carry the increased number of items.

The change/delta quantity value must be positive, and must be added to the quantity
of the product already loaded onto the van as applicable.  And if the product
already exists on the van, then the existing price must not be changed. */
-- -----------------------------------------------------------------------------
drop procedure if exists load_van;
delimiter //
create procedure load_van (in ip_id varchar(40), in ip_tag integer, in ip_barcode varchar(40),
	in ip_more_packages integer, in ip_price integer)
sp_main: begin
	-- ensure that the van being loaded is owned by the service
	-- ensure that the product is valid
    -- ensure that the van is located at the service home base
	-- ensure that the quantity of new packages is greater than zero
	-- ensure that the van has sufficient capacity to carry the new packages
    -- add more of the product to the van
    if not exists (select 1 from vans where id = ip_id and tag = ip_tag) or
       not exists (select 1 from products where barcode = ip_barcode) or
       ip_more_packages <= 0 or
       not exists (select 1 from delivery_services ds, vans v where ds.id = ip_id and v.located_at = ds.home_base and v.id = ip_id and v.tag = ip_tag) or
       (select capacity from vans where id = ip_id and tag = ip_tag) < ip_more_packages then
        leave sp_main;
    end if;

    insert into contain (id, tag, barcode, quantity, price)
    values (ip_id, ip_tag, ip_barcode, ip_more_packages, ip_price)
    on duplicate key update quantity = quantity + ip_more_packages;
end //
delimiter ;

-- [16] refuel_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add more fuel to a van. The van can only
be refueled if it's located at the delivery service's home base. */
-- -----------------------------------------------------------------------------
drop procedure if exists refuel_van;
delimiter //
create procedure refuel_van (in ip_id varchar(40), in ip_tag integer, in ip_more_fuel integer)
sp_main: begin
	-- ensure that the van being switched is valid and owned by the service
    -- ensure that the van is located at the service home base
    if not exists (select 1 from vans where id = ip_id and tag = ip_tag) or
       not exists (select 1 from delivery_services ds, vans v where ds.id = ip_id and v.located_at = ds.home_base and v.id = ip_id and v.tag = ip_tag) then
        leave sp_main;
    end if;

    update vans
    set fuel = fuel + ip_more_fuel
    where id = ip_id and tag = ip_tag;
end //
delimiter ;

-- [17] drive_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to move a single van to a new
location (i.e., destination). This will also update the respective driver's 
experience and van's fuel. The main constraints on the van(s) being able to 
move to a new  location are fuel and space.  A van can only move to a destination
if it has enough fuel to reach the destination and still move from the destination
back to home base.  And a van can only move to a destination if there's enough
space remaining at the destination. */
-- -----------------------------------------------------------------------------
drop function if exists fuel_required;
delimiter //
create function fuel_required (ip_departure varchar(40), ip_arrival varchar(40))
	returns integer reads sql data
begin
	if (ip_departure = ip_arrival) then return 0;
    else return (select 1 + truncate(sqrt(power(arrival.x_coord - departure.x_coord, 2) + power(arrival.y_coord - departure.y_coord, 2)), 0) as fuel
		from (select x_coord, y_coord from locations where label = ip_departure) as departure,
        (select x_coord, y_coord from locations where label = ip_arrival) as arrival);
	end if;
end //
delimiter ;

drop procedure if exists drive_van;
delimiter //
create procedure drive_van (in ip_id varchar(40), in ip_tag integer, in ip_destination varchar(40))
sp_main: begin
    -- ensure that the destination is a valid location
    -- ensure that the van isn't already at the location
    -- ensure that the van has enough fuel to reach the destination and (then) home base
    -- ensure that the van has enough space at the destination for the trip
    declare home_base varchar(40);
    declare required_fuel_to_destination integer;
    declare required_fuel_to_return integer;
    declare total_fuel_required integer;
    declare available_fuel integer;
    declare available_space integer;
    declare current_population integer;
    declare driver_id varchar(40);

    -- Ensure that the destination is a valid location
    if exists (select 1 from locations where label = ip_destination) then
        -- Ensure that the van isn't already at the location
        if not exists (select 1 from vans where id = ip_id and tag =
ip_tag and located_at = ip_destination) then
            -- Ensure that the van has enough fuel to reach the destination and return to home base
            select ds.home_base into home_base
            from vans v
            join delivery_services ds on v.id = ds.id
            where v.id = ip_id and v.tag = ip_tag;

            set required_fuel_to_destination = fuel_required((select
located_at from vans where id = ip_id and tag = ip_tag),
ip_destination);
            set required_fuel_to_return =
fuel_required(ip_destination, home_base);
            set total_fuel_required = required_fuel_to_destination +
required_fuel_to_return;

            select fuel into available_fuel from vans where id = ip_id
and tag = ip_tag;

            if available_fuel >= total_fuel_required then
                select space into available_space from locations where
label = ip_destination;
                select count(*) into current_population from vans
where located_at = ip_destination;

                -- Ensure that there is enough space at the destination for the van
                if available_space - current_population > 0 then
                    update vans
                    set located_at = ip_destination,
                        fuel = fuel - required_fuel_to_destination
                    where id = ip_id and tag = ip_tag;

                    select driven_by into driver_id
                    from vans
                    where id = ip_id and tag = ip_tag;

                    update drivers
                    set successful_trips = successful_trips + 1
                    where username = driver_id;
                end if;
            end if;
        end if;


    end if;
end //
delimiter ;

-- [18] purchase_product()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a business to purchase products from a van
at its current location.  The van must have the desired quantity of the product
being purchased.  And the business must have enough money to purchase the
products.  If the transaction is otherwise valid, then the van and business
information must be changed appropriately.  Finally, we need to ensure that all
quantities in the payload table (post transaction) are greater than zero. */
-- -----------------------------------------------------------------------------
drop procedure if exists purchase_product;
delimiter //
create procedure purchase_product (in ip_long_name varchar(40), in ip_id varchar(40),
	in ip_tag integer, in ip_barcode varchar(40), in ip_quantity integer)
sp_main: begin
	-- ensure that the business is valid
    -- ensure that the van is valid and exists at the business's location
	-- ensure that the van has enough of the requested product
	-- update the van's payload
    -- update the monies spent and gained for the van and business
    -- ensure all quantities in the contain table are greater than zero
    declare available_quantity integer; 
    declare product_price decimal(10,2);
    declare total_cost decimal(10,2);
    
    
   if exists (select 1 from businesses where long_name = ip_long_name) then
        -- Ensure that the van is valid and exists at the business's location
        if exists (select 1 from vans v join businesses b on b.location = v.located_at
			where v.id = ip_id and v.tag = ip_tag and b.long_name = ip_long_name) then
            -- Ensure that the van has enough of the requested product
            select quantity into available_quantity from contain where id = ip_id and tag = ip_tag and barcode = ip_barcode;
			select price into product_price from contain where id = ip_id and tag = ip_tag and barcode = ip_barcode;
			if available_quantity >= ip_quantity then
                -- Calculate the total cost
                set total_cost = product_price * ip_quantity;

                -- Update the van's payload
                update contain
                set quantity = quantity - ip_quantity
                where id = ip_id and tag = ip_tag and barcode = ip_barcode;

                -- Update the monies spent and gained for the van and business
                update businesses
                set spent = spent + total_cost
                where long_name = ip_long_name;

                update vans
                set sales = sales + total_cost
                where id = ip_id and tag = ip_tag;

                -- Ensure all quantities in the contain table are greater than zero 
                delete from contain where quantity <= 0 and id = ip_id and tag = ip_tag and barcode = ip_barcode;
            end if;
        end if;
    end if;
end //
delimiter ;

-- [19] remove_product()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a product from the system.  The removal can
occur if, and only if, the product is not being carried by any vans. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_product;
delimiter //
create procedure remove_product (in ip_barcode varchar(40))
sp_main: begin
	-- ensure that the product exists
    -- ensure that the product is not being carried by any vans
    if not exists (select 1 from products where barcode = ip_barcode) or
       exists (select 1 from contain where barcode = ip_barcode) then
        leave sp_main;
    end if;

    delete from products
    where barcode = ip_barcode;
end //
delimiter ;

-- [20] remove_van()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a van from the system.  The removal can
occur if, and only if, the van is not carrying any products.*/
-- -----------------------------------------------------------------------------
drop procedure if exists remove_van;
delimiter //
create procedure remove_van (in ip_id varchar(40), in ip_tag integer)
sp_main: begin
	-- ensure that the van exists
    -- ensure that the van is not carrying any products
    if not exists (select 1 from vans where id = ip_id and tag = ip_tag) or
       exists (select 1 from contain where id = ip_id and tag = ip_tag) then
        leave sp_main;
    end if;

    delete from vans
    where id = ip_id and tag = ip_tag;
end //
delimiter ;

-- [21] remove_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a driver from the system.  The removal can
occur if, and only if, the driver is not controlling any vans.  
The driver's information must be completely removed from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_driver_role;
delimiter //
create procedure remove_driver_role (in ip_username varchar(40))
sp_main: begin
	-- ensure that the driver exists
    -- ensure that the driver is not controlling any vans
    -- remove all remaining information
    if exists (select 1 from drivers where username = ip_username) then
		if not exists (select 1 from vans where driven_by = ip_username) then
			delete from drivers where username = ip_username;
            
            delete from work_for where username = ip_username; 
            delete from employees where username = ip_username; 
            delete from users where username = ip_username;
		end if; 
	end if;
end //
delimiter ;

-- [22] display_owner_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an owner.
For each owner, it includes the owner's information, along with the number of
businesses for which they provide funds and the number of different places where
those businesses are located.  It also includes the highest and lowest ratings
for each of those businesses, as well as the total amount of debt based on the
monies spent purchasing products by all of those businesses. And if an owner
doesn't fund any businesses then display zeros for the highs, lows and debt. */
-- -----------------------------------------------------------------------------
create or replace view display_owner_view as
select u.username, u.first_name, u.last_name, u.address, COUNT(DISTINCT f.business) as number_businesses,
COUNT(DISTINCT b.location) as number_locations, COALESCE(MAX(b.rating), 0) as best_rating, COALESCE(MIN(b.rating), 0) AS worst_rating,
COALESCE(SUM(b.spent), 0) AS debt FROM business_owners b_o INNER JOIN users u ON b_o.username = u.username
LEFT JOIN fund f on b_o.username = f.username LEFT JOIN businesses b ON f.business = b.long_name
GROUP BY u.username;



-- [23] display_employee_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an employee.
For each employee, it includes the username, tax identifier, salary, hiring date and
experience level, along with license identifer and driving experience (if applicable,
'n/a' if not), and a 'yes' or 'no' depending on the manager status of the employee. */
-- -----------------------------------------------------------------------------
create or replace view display_employee_view as
select e.username, e.taxID, e.salary, e.hired, e.experience, COALESCE(d.licenseID, 'n/a') as licenseID,
COALESCE(CAST(d.successful_trips AS CHAR), 'n/a') AS d_experience,
CASE
	WHEN ds.manager IS NOT NULL THEN 'yes'
    ELSE 'no'
END as manager
FROM employees e LEFT JOIN drivers d ON e.username = d.username LEFT JOIN delivery_services ds on e.username=ds.manager;


-- [24] display_driver_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a driver.
For each driver, it includes the username, licenseID and drivering experience, along
with the number of vans that they are controlling. */
-- -----------------------------------------------------------------------------
create or replace view display_driver_view as
select d.username, d.licenseID, d.successful_trips, COALESCE(COUNT(v.id), 0) as vans_controlled from drivers d LEFT JOIN
vans v on d.username=v.driven_by GROUP BY d.username;

-- [25] display_location_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a location.
For each location, it includes the label, x- and y- coordinates, along with the
name of the business or service at that location, the number of vans as well as 
the identifiers of the vans at the location (sorted by the tag), and both the 
total and remaining capacity at the location. */
-- -----------------------------------------------------------------------------
create or replace view display_location_view as
select l.label, COALESCE(b.long_name, ds.long_name) as business, l.x_coord, l.y_coord, l.space, van_table.number_vans,
van_table.van_table.van_list, l.space-van_table.number_vans as space_left  FROM locations l
LEFT JOIN businesses b ON l.label=b.location LEFT JOIN delivery_services ds ON l.label=ds.home_base INNER JOIN
(SELECT located_at, COUNT(*) as number_vans, GROUP_CONCAT(CONCAT(id, tag) ORDER BY tag SEPARATOR ',') as van_list FROM vans GROUP BY located_at) van_table ON van_table.located_at=l.label;

-- [26] display_product_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of the products.
For each product that is being carried by at least one van, it includes a list of
the various locations where it can be purchased, along with the total number of packages
that can be purchased and the lowest and highest prices at which the product is being
sold at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_product_view as
select p.iname, v.located_at, SUM(c.quantity), MIN(c.price), MAX(c.price) FROM products p INNER JOIN contain c ON p.barcode = c.barcode
INNER JOIN vans v ON c.id = v.id AND c.tag = v.tag GROUP BY p.barcode, v.located_at;

-- [27] display_service_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a delivery
service.  It includes the identifier, name, home base location and manager for the
service, along with the total sales from the vans.  It must also include the number
of unique products along with the total cost and weight of those products being
carried by the vans. */
-- -----------------------------------------------------------------------------
create or replace view display_service_view as
select ds.id, ds.long_name, ds.home_base, ds.manager, COALESCE(sales.total_sales, 0), COALESCE(prod.num_products, 0),
COALESCE(prod.cost, 0), COALESCE(prod.weight, 0) FROM delivery_services ds LEFT JOIN
(SELECT v.id as vid, SUM(v.sales) AS total_sales FROM vans v GROUP BY v.id) as sales ON ds.id = sales.vid LEFT JOIN
(SELECT v.id as vid, COUNT(DISTINCT c.barcode) as num_products, SUM(c.price * c.quantity) as cost, SUM(p.weight * c.quantity) as weight
FROM vans v LEFT JOIN contain c on v.id = c.id and v.tag = c.tag LEFT JOIN products p on c.barcode = p.barcode GROUP BY v.id) as prod on ds.id = prod.vid;
