import SwiftUI
import WebKit

struct PlotlyWaterfallView: View {
    @State private var timeRange: String = "month"

    var body: some View {
        VStack(spacing: 0) {
            // Time range selector
            HStack(spacing: 12) {
                ForEach(["day", "week", "month"], id: \.self) { range in
                    Button(action: { timeRange = range }) {
                        Text(range.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(timeRange == range ? .furgMint : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(timeRange == range ? Color.furgMint.opacity(0.2) : Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)

            // Web view with Plotly
            WaterfallChartWebView(timeRange: timeRange)
                .frame(height: 400)
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .cornerRadius(16)
        .padding(16)
    }
}

struct WaterfallChartWebView: UIViewRepresentable {
    let timeRange: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)
        webView.isOpaque = false

        let htmlString = generateWaterfallHTML(timeRange: timeRange)
        webView.loadHTMLString(htmlString, baseURL: nil)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString = generateWaterfallHTML(timeRange: timeRange)
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    private func generateWaterfallHTML(timeRange: String) -> String {
        // Data for waterfall
        let (labels, values, measures) = getWaterfallData(timeRange: timeRange)

        let labelsJSON = labels.map { "\"\($0)\"" }.joined(separator: ",")
        let valuesJSON = values.map { String($0) }.joined(separator: ",")
        let measuresJSON = measures.map { "\"\($0)\"" }.joined(separator: ",")

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
            <style>
                body { margin: 0; padding: 0; background-color: #13131f; }
                #chart { width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div id="chart"></div>
            <script>
                var data = [{
                    type: "waterfall",
                    orientation: "v",
                    x: [\(labelsJSON)],
                    textposition: "outside",
                    text: [\(labelsJSON)],
                    y: [\(valuesJSON)],
                    measure: [\(measuresJSON)],
                    increase: {marker: {color: "#4FBF85"}},
                    decrease: {marker: {color: "#FF6B6B"}},
                    totals: {marker: {color: "#8B9DC3"}},
                    connector: {line: {color: "#666"}},
                    hovertemplate: '<b>%{x}</b><br>Amount: $%{y:,.0f}<extra></extra>'
                }];

                var layout = {
                    title: { text: "Balance Waterfall", font: {color: "#fff", size: 16} },
                    showlegend: false,
                    margin: {l: 60, r: 40, t: 50, b: 40},
                    paper_bgcolor: "#13131f",
                    plot_bgcolor: "#13131f",
                    font: {color: "#999", family: "system-ui", size: 12},
                    xaxis: {
                        showgrid: false,
                        zeroline: false,
                        color: "#666"
                    },
                    yaxis: {
                        showgrid: true,
                        gridcolor: "#333",
                        zeroline: false,
                        color: "#666",
                        tickformat: "$.0f"
                    },
                    hovermode: "x unified"
                };

                var config = {
                    responsive: true,
                    displayModeBar: false,
                    staticPlot: false
                };

                Plotly.newPlot('chart', data, layout, config);
            </script>
        </body>
        </html>
        """
    }

    private func getWaterfallData(timeRange: String) -> ([String], [Double], [String]) {
        // Mock data for demonstration
        let startBalance = 12000.0
        let expenses: [(String, Double)] = [
            ("Groceries", 45),
            ("Dining", 65),
            ("Transport", 30),
            ("Shopping", 120),
            ("Utilities", 85),
            ("Other", 55)
        ]

        var labels = ["Start Balance"]
        var values = [startBalance]
        var measures = ["absolute"]

        var runningBalance = startBalance
        for (category, amount) in expenses {
            labels.append(category)
            values.append(amount)
            measures.append("relative")
            runningBalance -= amount
        }

        labels.append("End Balance")
        values.append(runningBalance)
        measures.append("total")

        return (labels, values, measures)
    }
}

#Preview {
    PlotlyWaterfallView()
        .frame(height: 500)
}
