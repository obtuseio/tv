import './node_modules/semantic-ui-css/semantic.min.css';
import Highcharts from 'highcharts';
import regression from 'regression';

import Elm from './src/Main.elm';
import './src/Main.css';

const div = document.getElementById('app');
div.className = 'ui container';
const app = Elm.Main.embed(div);

app.ports.plot.subscribe(chart => requestAnimationFrame(() => plot(chart)));

// https://stackoverflow.com/a/12646864
function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    let j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

function plot({show, ratingFromZero}) {
  const colors = shuffle([
    '#1abc9c',
    '#2ecc71',
    '#3498db',
    '#9b59b6',
    '#34495e',
    '#f1c40f',
    '#e67e22',
    '#e74c3c',
  ]);

  const episodes = show.episodes;

  const minRating = Math.min.apply(Math, episodes.map(e => e.rating.average));
  const maxSeason = Math.max.apply(Math, episodes.map(e => e.seasonNumber));

  const series = [];

  for (let seasonNumber = 1; seasonNumber <= maxSeason; seasonNumber++) {
    const [[x1, y1], [x2, y2]] = regressionLine(
      episodes.filter(e => e.seasonNumber === seasonNumber)
    );

    let push = 0;
    for (
      let i = 0;
      i < episodes.length && episodes[i].seasonNumber !== seasonNumber;
      i++, push++
    );

    series.push({
      type: 'line',
      name: `Season ${seasonNumber}`,
      data: [[x1 + push, y1], [x2 + push, y2]],
      marker: {
        enabled: false,
        symbol: 'square',
      },
      tooltip: {
        headerFormat: '',
        pointFormat: `<strong>Season ${seasonNumber} Trend</strong><br>
        ${y1.toFixed(2)} → ${y2.toFixed(2)}`,
      },
      color: colors[seasonNumber % colors.length],
    });

    series.push({
      type: 'scatter',
      name: `Season ${seasonNumber}`,
      data: episodes.map(e => {
        if (e.seasonNumber === seasonNumber) {
          return {
            tooltip: `<strong>[${e.seasonNumber}.${e.episodeNumber}] ${
              e.primaryTitle
            }</strong><br>
            ${e.rating.average} - ${e.rating.count.toLocaleString()} votes`,
            y: e.rating.average,
          };
        } else {
          return null;
        }
      }),
      marker: {
        symbol: 'circle',
        radius: 3,
      },
      color: colors[seasonNumber % colors.length],
      tooltip: {
        headerFormat: '',
        pointFormat: '{point.tooltip}',
      },
    });
  }

  Highcharts.chart('chart', {
    chart: {
      height: 500,
    },
    credits: {
      enabled: false,
    },
    xAxis: {
      title: {
        text: 'Episode #',
      },
    },
    yAxis: {
      min: ratingFromZero ? 0 : minRating,
      max: 10,
      title: {
        text: 'IMDb Rating',
      },
    },
    title: {
      text: `${show.primaryTitle} Episodes' IMDb Ratings`,
    },
    series: series,
    legend: false,
  });
}

function regressionLine(episodes) {
  const xys = episodes.map((e, i) => [i, e.rating.average]);
  const [m, c] = regression.linear(xys).equation;
  const xs = xys.map(xy => xy[0]);
  const minX = Math.min.apply(Math, xs);
  const maxX = Math.max.apply(Math, xs);
  return [[minX, m * minX + c], [maxX, m * maxX + c]];
}
