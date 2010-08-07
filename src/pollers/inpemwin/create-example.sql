#
# $Id$
#

create table inpemwin (devicenumber int(11) not null,
       time bigint(20) not null,
       npemwind_start_time bigint(20) not null,
       num_clients int(11) not null,
       upstream_ip varchar(45) not null,
       upstream_port int(11) not null,
       upstream_connect_time int(11) not null,
       upstream_consecutive_packets int(11) not null,
       client_table text);
