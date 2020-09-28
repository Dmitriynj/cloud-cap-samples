using {sap.capire.certificates as my} from '../db/schema';

service CertificatesService @(requires : ['identified-user']) {
    @readonly
    entity Certificates       as projection on my.Certificates;

    @readonly
    entity CertificatesToTags as projection on my.CertificatesToTags;

    @readonly
    entity Tags               as projection on my.Tags;

    @readonly
    entity Orders             as projection on my.Orders;

    @(restrict : [{
        grant : '*',
        to    : 'authenticated-user'
    }, ]) action orderCertificate(certificate_ID : my.Certificates.ID, amount : Integer);


    @(restrict : [{
        grant : '*',
        to    : 'authenticated-user'
    }, ])
    action cancelOrder(ID : my.Orders.ID);
}
