
const path = require('path');
const VueLoaderPlugin = require('vue-loader/lib/plugin')

module.exports = {

  output: {
    path: path.resolve(__dirname, 'public/js')
  },

  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader'
      }
    ]
  },

  plugins: [
    new VueLoaderPlugin()
  ],

};
