using {sap.capire.streaming as my} from '../db/schema';

service StreamMediaService @(path : '/streaming') {
    entity Media as projection on my.Media;
}
