using {
    managed,
    sap,
    cuid
} from '@sap/cds/common';

namespace sap.capire.certificates;

entity Certificates : cuid, managed {
    title   : String(111);
    instock : Integer;
    price   : Integer;
    tags    : Association to many CertificatesToTags
                  on tags.certificate = $self;
    orders  : Association to many Orders
                  on orders.certificate = $self;
}

entity CertificatesToTags {
    key certificate : Association to Certificates;
    key tag         : Association to Tags;
}

entity Tags : cuid, managed {
    certificates : Association to many CertificatesToTags
                       on certificates.tag = $self;
    title        : String(111);
}

entity Orders : cuid, managed {
    certificate : Association to Certificates;
    amount      : Integer;
}
