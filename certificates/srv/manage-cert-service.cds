using {sap.capire.certificates as my} from '../db/schema';

service ManageCertificates @(requires : [
'admin',
'content-creator'
]) {
    entity Certificates as projection on my.Certificates;
    entity Tags         as projection on my.Tags;

    @(restrict : [{grant : ['DELETE']}])
    entity Orders       as projection on my.Orders;

    entity CertificatesToTags @(restrict : [{
        grant : ['*'],
        where : '$user.level > 1'
    }])                 as projection on my.CertificatesToTags;
}
