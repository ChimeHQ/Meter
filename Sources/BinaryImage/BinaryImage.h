#ifndef BinaryImage_h
#define BinaryImage_h

#define _Noescape __attribute__((noescape))
#define ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define ASSUME_NONNULL_END   _Pragma("clang assume_nonnull end")

#include <stdint.h>
#include <stdbool.h>
#include <mach-o/loader.h>

#if __OBJC__
#import <Foundation/Foundation.h>
#endif

ASSUME_NONNULL_BEGIN

typedef struct {
    uintptr_t address;
    intptr_t loadAddress;
    uintptr_t length;
} MachODataRegion;

typedef struct {
    const uint8_t* uuid;
    intptr_t slide;
    MachODataRegion ehFrameRegion;
    MachODataRegion unwindInfoRegion;
    uintptr_t loadAddress;
    uintptr_t textSize;
    const char* path;
} MachOData;

#if __LP64__
typedef struct mach_header_64 MachOHeader;
typedef struct section_64 MachOSection;
typedef struct segment_command_64 SegmentCommand;
typedef struct section_64 Section;

const static uint32_t LCSegment = LC_SEGMENT_64;
#else
typedef struct mach_header MachOHeader;
typedef struct section MachOSection;
typedef struct segment_command SegmentCommand;
typedef struct section Section;

const static uint32_t LCSegment = LC_SEGMENT;
#endif

typedef struct {
    const char* name;
    const MachOHeader* header;
} BinaryImage;

typedef void (^BinaryImageIterator)(BinaryImage image, bool* stop);

void BinaryImageEnumerateLoadedImages(_Noescape BinaryImageIterator iterator);

typedef void (^BinaryImageLoadCommandIterator)(const struct load_command* lcmd, uint32_t cmdCode, bool* stop);

void BinaryImageEnumerateLoadCommands(const MachOHeader* header, _Noescape BinaryImageLoadCommandIterator iterator);

uint8_t* _Nullable BinaryImageGetUUIDBytesFromLoadCommand(const struct load_command* lcmd, uint32_t cmdCode);

#if __OBJC__
NSUUID* _Nullable BinaryuImageUUIDFromLoadCommand(const struct load_command* lcmd, uint32_t cmdCode);
NSUUID* BinaryImageGetUUID(const MachOHeader* header);

void LogException(NSException* exception, NSString* path);
#endif

ASSUME_NONNULL_END

#endif /* BinaryImage_h */
