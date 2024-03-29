local architecture

do -- get processor architecture
    local architecturePatterns = {
        ['^x86$'] = 'x86',
        ['i[%d]86'] = 'x86',
        ['AMD64'] = 'x86',
        ['x86_64'] = 'x86',
        ['^x64$'] = 'x64',
    }
    
    architecture = os.getenv'PROCESSOR_ARCHITECTURE'
    
    for pattern, name in next, architecturePatterns do
        if architecture:match(pattern) then
            architecture = name
            break
        end
    end
end

local LONG         = architecture == 'x86' and 4 or 8
local DWORD        = 4
local WORD         = 2
local FXPT2DOT30   = LONG
local CIEXYZ       = FXPT2DOT30 * 3
local CIEXYZTRIPLE = CIEXYZ * 3

local BI_RGB                  = 0x0000
local BI_BITFIELDS            = 0x0003

local LCS_sRGB                = 0x73524742
local LCS_WINDOWS_COLOR_SPACE = 0x57696E20

local BITMAPV5HEADER          = 0x007C
local BITMAPV4HEADER          = 0x006C
local BITMAPINFOHEADER        = 0x0028
local BITMAPCOREHEADER        = 0x0012

local function bytesToInt(bytes, hassign, bigendian)
    local result = 0
    local size = #bytes
    local fsize = 2^size - 1

    for i = bigendian and 1 or #bytes, bigendian and #bytes or 1, bigendian and 1 or -1 do
        local byte = bytes:sub(i, i):byte()
        result = (result << 8) + byte
    end
    if result > 2^(size - 1) - 1 and hassign then
        result = result - fsize + 1
    end
    if result > 0x7FFFFFFF then
        return result - 2^(size * 8)
    else
        return result
    end
end

local function readInt16(stream)  return bytesToInt(stream:read(WORD), true)  end
local function readUint16(stream) return bytesToInt(stream:read(WORD))        end
local function readInt32(stream)  return bytesToInt(stream:read(DWORD), true) end
local function readUint32(stream) return bytesToInt(stream:read(DWORD))       end
local function readLong(stream)   return bytesToInt(stream:read(LONG), true)  end

function bmpDecode(path)
    local result = {}

    local file = io.open(path, 'rb')

    if file:read(WORD) ~= '\66\77' then error'not a bitmap' end

    local size = readInt32(file)
    file:read(DWORD)
    local mappoint = readUint32(file)

    local dibInfo = {}

    local dibSize = readUint32(file)
    dibInfo.size = dibSize

    if dibSize == BITMAPV5HEADER then
        local v5Width       = readLong  (file)
        local v5Height      = readLong  (file)
        local v5Planes      = readUint16(file)
        local v5BitCount    = readUint16(file)
        local v5Compression = readUint32(file)
        local v5ImageSize   = readUint32(file)
        local v5XPelsPerMet = readLong  (file)
        local v5YPelsPerMet = readLong  (file)
        local v5ClrUser     = readUint32(file)
        local v5ClrImport   = readUint32(file)
        local v5RedMask     = readUint32(file)
        local v5BlueMask    = readUint32(file)
        local v5GreenMask   = readUint32(file)
        local v5AlphaMask   = readUint32(file)
        local v5CStype      = readUint32(file)
        file:read(CIEXYZTRIPLE)
        file:read(DWORD * 3)
        local v5Intent      = readUint32(file)
        local v5ProfileData = readUint32(file)
        local v5ProfileSize = readUint32(file)
        file:read(DWORD)

        dibInfo.planes      = v5Planes
        dibInfo.csType      = v5CStype
        dibInfo.width       = v5Width
        dibInfo.height      = v5Height
        dibInfo.bitCount    = v5BitCount
        dibInfo.compression = v5Compression
        dibInfo.imageSize   = v5ImageSize
        dibInfo.redMask     = v5RedMask
        dibInfo.blueMask    = v5BlueMask
        dibInfo.greenMask   = v5GreenMask
        dibInfo.alphaMask   = v5AlphaMask
    elseif dibSize == BITMAPV4HEADER then
        local v4Width        = readLong  (file)
        local v4Height       = readLong  (file)
        local v4Planes       = readUint16(file)
        local v4BitCount     = readUint16(file)
        local v4Compression  = readUint32(file)
        local v4ImageSize    = readUint32(file)
        local v4XPerMeter    = readLong  (file)
        local v4YPerMeter    = readLong  (file)
        local v4ClrUsed      = readUint32(file)
        local v4ClrImportant = readUint32(file)
        local v4RedMask      = readUint32(file)
        local v4GreenMask    = readUint32(file)
        local v4BlueMask     = readUint32(file)
        local v4AlphaMask    = readUint32(file)
        local v4CStype       = readUint32(file)
        file:read(CIEXYZTRIPLE)
        file:read(DWORD * 3)

        dibInfo.planes      = v4Planes
        dibInfo.csType      = v4CStype
        dibInfo.width       = v4Width
        dibInfo.height      = v4Width
        dibInfo.bitCount    = v4BitCount
        dibInfo.compression = v4Compression
        dibInfo.imageSize   = v4ImageSize
        dibInfo.redMask     = v4RedMask
        dibInfo.blueMask    = v4BlueMask
        dibInfo.greenMask   = v4GreenMask
        dibInfo.alphaMask   = v4AlphaMask
    elseif dibSize == BITMAPINFOHEADER then
        local width        = readLong  (file)
        local height       = readLong  (file)
        local planes       = readUint16(file)
        local bitCount     = readUint16(file)
        local compression  = readUint32(file)
        local imageSize    = readUint32(file)
        local xPerMeter    = readLong  (file)
        local yPerMeter    = readLong  (file)
        local crlUsed      = readUint32(file)
        local crlImportant = readUint32(file)

        dibInfo.planes      = planes
        dibInfo.csType      = csType
        dibInfo.width       = width
        dibInfo.height      = height
        dibInfo.bitCount    = bitCount
        dibInfo.compression = compression
        dibInfo.imageSize   = imageSize
    elseif dibSize == BITMAPCOREHEADER then
        local width    = readInt16 (file)
        local height   = readInt16 (file)
        local planes   = readUint16(file)
        local bitCount = readUint16(file)

        dibInfo.planes   = planes
        dibInfo.width    = width
        dibInfo.height   = height
        dibInfo.bitCount = bitCount
    else
        error'unsupported DIB structure'
    end

    do
        if dibSize ~= BITMAPCOREHEADER
        and dibInfo.compression ~= BI_RGB and dibInfo.compression ~= BI_BITFIELDS then
            error'unsupported compression method'
        end
        if dibInfo.planes ~= 1 then
            error'the number of planes cannot be more or less than one'
        end
        if dibSize ~= BITMAPCOREHEADER 
        and dibInfo.imageSize == 0 and  dibInfo.compression ~= BI_RGB then
            error'image size cannot be zero'
        end
        if dibSize ~= BITMAPCOREHEADER
        and dibInfo.csType ~= LCS_WINDOWS_COLOR_SPACE and dibInfo.csType ~= LCS_sRGB then 
            error'unsupported color space DIB' 
        end
    end

    file:seek('set', mappoint)

    local height = math.abs(dibInfo.height)

    result.height = height
    result.width = dibInfo.height

    local iterateStart = dibSize == BITMAPCOREHEADER and 1      or dibInfo.height < 0 and 1      or height
    local iterateEnd   = dibSize == BITMAPCOREHEADER and height or dibInfo.height < 0 and height or 1
    local iterateInc   = dibSize == BITMAPCOREHEADER and 1      or dibInfo.height < 0 and 1      or -1

    local pixels = {}

    local byteCount = dibInfo.bitCount >> 3

    for y = iterateStart, iterateEnd, iterateInc do
        local row = {}

        for x = 1, dibInfo.width do
            local bytes = bytesToInt(file:read(byteCount))

            local pixel = {}

            if dibInfo.compression == BI_RGB then
                pixel.R = (bytes & 0xFF0000) >> 16
                pixel.G = (bytes & 0x00FF00) >> 8
                pixel.B = bytes & 0x0000FF
            elseif dibInfo.compression == BI_BITFIELDS then
                pixel.R = (bytes & dibInfo.redMask) >> 16
                pixel.G = (bytes & dibInfo.greenMask) >> 8
                pixel.B = bytes & dibInfo.blueMask
            end

            row[x] = pixel
        end

        pixels[y] = row
    end

    result.rows = pixels

    file:close()

    return result
end
