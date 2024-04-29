import UIKit
import SwiftUI
import Ikemen

struct OutlineStringView: UIViewRepresentable {
    let text: String
    let font: () -> UIFont // NOTE: simple UIFont cause error: reason: '-[__SwiftValue fontDescriptor]: unrecognized selector sent to instance
    let textColor: UIColor
    let strokeWidth: Double
    let strokeColor: UIColor
    let size: CGSize
    func makeUIView(context: Context) -> UIView {
        UIView() ※ { v in
            v.addSubview(UILabel() ※ {
                $0.attributedText = .init(string: text, attributes: [
                    .font: font(),
                    // Supply a negative value for NSStrokeWidthAttributeName when you wish to draw a string that is both filled and stroked. https://developer.apple.com/library/archive/qa/qa1531/_index.html
                    // However quality is not sufficient because connections of lines of a glyph also draws extra strokes...
                        .strokeWidth: strokeWidth,
                    .strokeColor: strokeColor,
                ])
            })
            v.addSubview(UILabel() ※ {
                $0.attributedText = .init(string: text, attributes: [
                    .font: font(),
                    .foregroundColor: textColor,
                ])
            })
            v.subviews.compactMap {$0 as? UILabel}.forEach {
                $0.textAlignment = .center
                $0.adjustsFontSizeToFitWidth = true
                $0.minimumScaleFactor = 0.01
                $0.translatesAutoresizingMaskIntoConstraints = false
                $0.leadingAnchor.constraint(equalTo: v.leadingAnchor).isActive = true
                $0.trailingAnchor.constraint(equalTo: v.trailingAnchor).isActive = true
                $0.topAnchor.constraint(equalTo: v.topAnchor).isActive = true
                $0.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
            }
        }
    }
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        size
    }
}
