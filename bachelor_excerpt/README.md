# bachelor thesis (wip)

for my bachelor thesis, I'm developing a small web-app which visualizes data and allows the user – non-technical experts – to explore them. The project builds on umap-explorer.

However, I developed the whole projection (the scatterplot) on my own using d3.js. That wasn't easy in the beginning, as d3.js is a low-level library, working directly with the dom, whereas React uses a virtual dom. For now, the solution is to integrate all dynamic d3 work into the react lifecycle. Inside the React Component of d3, d3 gets a reference to a svg element and can do its work therein.


![1](https://github.com/defo10/CodeSamples/blob/main/bachelor_excerpt/Screen%20Shot%202021-01-08%20at%2017.39.08.png)
