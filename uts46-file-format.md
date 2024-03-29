# Output file format

Codepoints are stored UTF-8-encoded.

All multibyte integers are little-endian.

| 8 or 12 bytes     | ...           |
|-------------------|---------------|
| [Header](#header) | [Data](#data) |

## Header

| 6 bytes      | 1 byte  | 1 byte | 4 bytes?     |
|--------------|---------|--------|--------------|
| magic number | version | flags  | optional crc |

- `magic number`: `"UTS#46"` (`0x55 0x54 0x53 0x23 0x34 0x36`).
- `version`: format version (1 byte; currently `0x01`).
- `flags`: See [Flags](#flags) below.
- `optional crc`: A CRC32 of the data section if `flags` has the `has crc` bit set.

### Flags

<table>
<thead>
<tr>
	<th> 7 </th>
	<th> 6 </th>
	<th> 5 </th>
	<th> 4 </th>
	<th> 3 </th>
	<th> 2 </th>
	<th> 1 </th>
	<th> 0 </th>
</tr>
</thead>
<tbody>
<tr>
	<td colspan="4"> unused   </td>
	<td> has crc </td>
	<td colspan="3"> compression </td>
</tr>
</tbody>
</table>

<!-- 
| 7 |  6  |  5  |  4  |    3    |  2  |  1  |  0  |
|-------------------------------------------------|
| unused           |||| has crc | compression   |||
 -->

- `has crc`: If set, there will be a CRC32 of the data section at the end of the header.
- `compression`: compression mode of the data.
	Currently identical to NSData’s [compression constants](https://developer.apple.com/documentation/foundation/nsdata/compressionalgorithm) + 1:
	
		- 0: no compression
		- 1: LZFSE
		- 2: LZ4
		- 3: LZMA
		- 4: ZLIB
		
## Data

The data section is a (possibly-compressed; see [Flags](#flags)) collection of data blocks of the format

	[marker][section data] ...

Section data formats:

If marker is `characterMap` (`0xFF`):

	[codepoint][mapped-codepoint ...][null] ...

If marker is `ignoredCharacters` (`0xFE`) or `disallowedCharacters` (`0xFD`):

	[codepoint-range] ...

If marker is `joiningTypes` (`0xFC`):


    [type][[codepoint-range] ...]


where `type` is one of `C`, `D`, `L`, `R`, or `T`.

`codepoint-range`: two codepoints, marking the first and last codepoints of a
closed range. Single-codepoint ranges have the same start and end codepoint.

