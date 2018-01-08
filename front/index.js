import './node_modules/semantic-ui-css/semantic.min.css';

import Elm from './src/Main.elm';
import './src/Main.css';

const app = document.getElementById('app');
app.className = 'ui container';

Elm.Main.embed(app);
