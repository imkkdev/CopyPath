import Foundation
import CoreGraphics
import ImageIO

// 用法: swift MakeIcon.swift <输入图> <输出PNG>
// 自动检测主体区域,裁剪并应用 macOS 圆角遮罩,输出带透明背景的方形图标
let args = CommandLine.arguments
guard args.count >= 3 else { exit(1) }
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

let src = CGImageSourceCreateWithURL(inURL as CFURL, nil)!
let img = CGImageSourceCreateImageAtIndex(src, 0, nil)!
let w = img.width, h = img.height

// 读取像素
var data = [UInt8](repeating: 0, count: w * h * 4)
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8,
                    bytesPerRow: w * 4, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))

// 检测主体(非浅色棋盘格背景)的边界
func isContent(_ x: Int, _ y: Int) -> Bool {
    let px = (y * w + x) * 4
    let r = Int(data[px]), g = Int(data[px + 1]), b = Int(data[px + 2])
    return b > 130 && (b - r) > 30
}

var minX = w, maxX = 0, minY = h, maxY = 0
var y = 0
while y < h {
    var x = 0
    while x < w {
        if isContent(x, y) {
            if x < minX { minX = x }
            if x > maxX { maxX = x }
            if y < minY { minY = y }
            if y > maxY { maxY = y }
        }
        x += 1
    }
    y += 1
}
let pad = 4
minX = max(0, minX - pad); minY = max(0, minY - pad)
maxX = min(w - 1, maxX + pad); maxY = min(h - 1, maxY + pad)
let cw = maxX - minX + 1, ch = maxY - minY + 1
let side = max(cw, ch)

// 输出 1024 画布,主体占 82%(贴近 Apple 图标网格)
let outSize = 1024
let contentSize = CGFloat(outSize) * 0.82
let origin = (CGFloat(outSize) - contentSize) / 2

let outCtx = CGContext(data: nil, width: outSize, height: outSize, bitsPerComponent: 8,
                       bytesPerRow: 0, space: cs,
                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let rect = CGRect(x: origin, y: origin, width: contentSize, height: contentSize)
outCtx.addPath(CGPath(roundedRect: rect,
                      cornerWidth: contentSize * 0.225,
                      cornerHeight: contentSize * 0.225, transform: nil))
outCtx.clip()

let cropped = img.cropping(to: CGRect(x: minX, y: h - maxY - 1, width: cw, height: ch))!
let scale = contentSize / CGFloat(side) * 1.07  // 放大裁切,去掉主体外的光晕背景
let drawW = CGFloat(cw) * scale, drawH = CGFloat(ch) * scale
outCtx.draw(cropped, in: CGRect(x: origin + (contentSize - drawW) / 2,
                                y: origin + (contentSize - drawH) / 2,
                                width: drawW, height: drawH))

let outImg = outCtx.makeImage()!
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, outImg, nil)
CGImageDestinationFinalize(dest)
print("图标已生成: 主体区域 \(cw)x\(ch) → \(outSize)x\(outSize)")
