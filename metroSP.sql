CREATE database metro;
use metro;


create table metroSP(
	linha char(20),
    status char(20),
    data char(10),
    hora char(6)
);

#Alter table metro rename metroSP;
CREATE USER 'metro_user'@'%' IDENTIFIED BY '123456';

#garantindo privilegios de select, update, insert e delete
GRANT SELECT,UPDATE,INSERT,DELETE ON metro.* TO 'metro_user'@'%';

# removendo o usuario
DROP USER 'metro_user'@'%';

select * from metroSP limit 20;