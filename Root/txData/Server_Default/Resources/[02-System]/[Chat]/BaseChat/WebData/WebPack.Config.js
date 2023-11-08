const CopyWebPackPlugin = require("Copy-WebPack-Plugin");
const HTMLWebPackPlugin = require("HTML-WebPack-Plugin");
const HTMLWebPackInlineSourcePlugin = require("HTML-WebPack-Inline-Source-Plugin");
const VUELoaderPlugin = require("VUE-Loader/Lib/Plugin");

module.exports = {
  mode: "production",
  entry: "./HTML/main.ts",
  module: {
    rules: [
      {
        test: /\.ts$/,
        loader: "TS-Loader",
        exclude: /Node_Modules/,
        options: {
          appendTsSuffixTo: [/\.vue$/]
        }
      },
      {
        test: /\.vue$/,
        loader: "VUE-Loader"
      }
    ]
  },
  plugins: [
    new CopyWebPackPlugin([
      {from: "HTML/index.css", to: "index.css"}
    ]),
    new HTMLWebPackPlugin({
      inlineSource: ".(js|css)$",
      template: "./HTML/index.html",
      filename: "ui.html"
    }),
    new HTMLWebPackInlineSourcePlugin(),
    new VUELoaderPlugin()
  ],
  resolve: {
    extensions: [".js", ".ts"]
  },
  output: {
    filename: "Chat.js",
    path: __dirname + "/Dist/"
  }
};
