using {managed} from '@sap/cds/common';

namespace sap.capire.streaming;

entity Media : managed {
    key ID    : UUID;
        media : LargeBinary @Core.MediaType : 'video/mp4'
}
