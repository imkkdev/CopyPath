import Foundation
import CoreGraphics
import ImageIO

// 程序化绘制「复制路径」图标:蓝色渐变圆角方块 + 白色斜杠
// 用法: swift DrawIcon.swift <输出PNG路径>
let outURL = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png")
let S = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: S, height: S, bitsPerComponent: 8,
                    bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// 主体占画布 82%,贴近 Apple 图标网格
let content = CGFloat(S) * 0.82
let origin = (CGFloat(S) - content) / 2
let rect = CGRect(x: origin, y: origin, width: content, height: content)
let radius = content * 0.225

ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
ctx.clip()

// 垂直蓝色渐变(上浅下深)
let colors = [CGColor(srgbRed: 0.30, green: 0.66, blue: 1.00, alpha: 1),
              CGColor(srgbRed: 0.02, green: 0.36, blue: 0.96, alpha: 1)] as CFArray
let grad = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: S / 2, y: S),
                       end: CGPoint(x: S / 2, y: 0), options: [])

// 白色斜杠:圆角长条旋转 -20°(CG 坐标系下即 "/" 方向)
ctx.saveGState()
ctx.translateBy(x: CGFloat(S) / 2, y: CGFloat(S) / 2)
ctx.rotate(by: -20 * .pi / 180)
let barW = content * 0.105
let barH = content * 0.62
ctx.addPath(CGPath(roundedRect: CGRect(x: -barW / 2, y: -barH / 2, width: barW, height: barH),
                   cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil))
ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
ctx.fillPath()
ctx.restoreGState()

let img = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("已绘制图标 → \(outURL.path)")
