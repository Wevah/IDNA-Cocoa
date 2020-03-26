//
//  uidna-min.h
//  Punycode
//
//  Created by Nate Weaver on 2020-03-22.
//

//  Minimal UIDNA API for Punycode-Cocoa.

#define U_STABLE extern
#define U_EXPORT2

typedef int8_t UBool;
typedef uint16_t UChar;

typedef enum UErrorCode {
    U_ZERO_ERROR =  0,
} UErrorCode;

#define U_SUCCESS(x) ((x)<=U_ZERO_ERROR)
#define U_FAILURE(x) ((x)>U_ZERO_ERROR)

enum {
    UIDNA_DEFAULT=0,
#ifndef U_HIDE_DEPRECATED_API
    UIDNA_ALLOW_UNASSIGNED=1,
#endif  /* U_HIDE_DEPRECATED_API */
    UIDNA_USE_STD3_RULES=2,
    UIDNA_CHECK_BIDI=4,
    UIDNA_CHECK_CONTEXTJ=8,
    UIDNA_NONTRANSITIONAL_TO_ASCII=0x10,
    UIDNA_NONTRANSITIONAL_TO_UNICODE=0x20,
    UIDNA_CHECK_CONTEXTO=0x40
};

typedef struct UIDNAInfo {
    int16_t size;
    UBool isTransitionalDifferent;
    UBool reservedB3;
    uint32_t errors;
    int32_t reservedI2;
    int32_t reservedI3;
} UIDNAInfo;

#define UIDNA_INFO_INITIALIZER { \
    (int16_t)sizeof(UIDNAInfo), \
    FALSE, FALSE, \
    0, 0, 0 }

struct UIDNA;
typedef struct UIDNA UIDNA;

U_STABLE UIDNA * U_EXPORT2
uidna_openUTS46(uint32_t options, UErrorCode *pErrorCode);

U_STABLE void U_EXPORT2
uidna_close(UIDNA *idna);

U_STABLE int32_t U_EXPORT2
uidna_nameToASCII(const UIDNA *idna,
                  const UChar *name, int32_t length,
                  UChar *dest, int32_t capacity,
                  UIDNAInfo *pInfo, UErrorCode *pErrorCode);

U_STABLE int32_t U_EXPORT2
uidna_nameToUnicode(const UIDNA *idna,
                    const UChar *name, int32_t length,
                    UChar *dest, int32_t capacity,
                    UIDNAInfo *pInfo, UErrorCode *pErrorCode);
