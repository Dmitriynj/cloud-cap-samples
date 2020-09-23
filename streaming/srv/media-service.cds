using {sap.capire.streaming as my} from '../db/schema';

@path     : '/streaming'
@requires : 'authenticated-user'
service StreamMediaService {
    entity Media as projection on my.Media;
}
