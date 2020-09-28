using {sap.capire.certificates as my} from '../../db/schema';

service TestOrders {
    entity Orders as projection on my.Orders;
}
