#import <Foundation/Foundation.h>

#include "BinaryImage.h"
#include <mach-o/dyld.h>

void BinaryImageEnumerateLoadedImages(BinaryImageIterator iterator) {
    for (uint32_t i = 0; i < _dyld_image_count(); ++i) {
        BinaryImage image = {0};

        image.name = _dyld_get_image_name(i);
        image.header = (MachOHeader*)_dyld_get_image_header(i);

        bool stop = false;

        iterator(image, &stop);

        if (stop) {
            break;
        }
    }
}

void BinaryImageEnumerateLoadCommands(const MachOHeader* header, BinaryImageLoadCommandIterator iterator) {
    if (header == NULL) {
        return;
    }

    const uint8_t *ptr = (uint8_t *)header + sizeof(MachOHeader);
    
    for (uint32_t i = 0; i < header->ncmds; ++i) {
        const struct load_command* const lcmd = (struct load_command*)ptr;
        const uint32_t cmdCode = lcmd->cmd & ~LC_REQ_DYLD;

        bool stop = false;

        iterator(lcmd, cmdCode, &stop);

        if (stop) {
            break;
        }

        ptr += lcmd->cmdsize;
    }
}

uint8_t* BinaryImageGetUUIDBytesFromLoadCommand(const struct load_command* lcmd, uint32_t cmdCode) {
    if (lcmd == NULL || cmdCode != LC_UUID) {
        return NULL;
    }

    return ((struct uuid_command*)lcmd)->uuid;
}

NSUUID* BinaryuImageUUIDFromLoadCommand(const struct load_command* lcmd, uint32_t cmdCode) {
    const uint8_t* bytes = BinaryImageGetUUIDBytesFromLoadCommand(lcmd, cmdCode);

    return [[NSUUID alloc] initWithUUIDBytes:bytes];
}

bool ImpactBinaryImageGetData(const MachOHeader* header, const char* path, MachOData* data) {
    if (header == NULL || data == NULL) {
        return false;
    }

    const uint8_t *ptr = (uint8_t *)header + sizeof(MachOHeader);

    data->loadAddress = (uintptr_t)header;
    data->path = path;

    return true;
}
