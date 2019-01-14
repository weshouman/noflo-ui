const noflo = require('noflo');
const octo = require('octo');

const githubGet = function(url, token, callback) {
  const api = octo.api();
  api.token(token);
  const request = api.get(url);
  request.on('success', function(res) {
    if (!res.body) {
      callback(new Error('No result received'));
      return;
    }
    return callback(null, res.body);
  });
  request.on('error', err => callback(err.body));
  return request();
};

const getTree = (repo, tree, token, callback) => githubGet(`/repos/${repo}/git/trees/${tree}`, token, callback);

var processTree = function(basePath, tree, entries, repo, token, out, callback) {
  const subTrees = [];
  const handled = [];
  for (let entry of Array.from(tree.tree)) {
    entry.fullPath = `${basePath}${entry.path}`;
    if (entry.type === 'tree') {
      subTrees.push(entry);
      continue;
    }

    for (let localEntry of Array.from(entries)) {
      if (entry.fullPath !== localEntry.path) {
        if (entry.fullPath !== localEntry.path.replace('\.fbp', '.json')) { continue; }
      }
      if (localEntry.type === 'graph') {
        localEntry.local.properties.sha = entry.sha;
        localEntry.local.properties.changed = false;
        handled.push(localEntry);
        out.graph.send(localEntry.local);
        continue;
      }
      localEntry.local.sha = entry.sha;
      localEntry.local.changed = false;
      handled.push(localEntry);
      if (localEntry.type === 'spec') {
        out.spec.send(localEntry.local);
        continue;
      }
      out.component.send(localEntry.local);
    }
  }

  for (let found of Array.from(handled)) {
    entries.splice(entries.indexOf(found), 1);
  }

  if (entries.length === 0) { return callback(); }

  return subTrees.forEach(subTree =>
    getTree(repo, subTree.sha, token, function(err, sTree) {
      if (err) { return callback(err); }
      return processTree(`${subTree.fullPath}/`, sTree, entries, repo, token, out, callback);
    })
  );
};

exports.getComponent = function() {
  const c = new noflo.Component;
  c.inPorts.add('in',
    {datatype: 'object'});
  c.inPorts.add('tree',
    {datatype: 'object'});
  c.inPorts.add('repository',
    {datatype: 'string'});
  c.inPorts.add('token', {
    datatype: 'string',
    description: 'GitHub API token',
    required: true
  }
  );
  c.outPorts.add('graph',
    {datatype: 'object'});
  c.outPorts.add('component',
    {datatype: 'object'});
  c.outPorts.add('spec',
    {datatype: 'object'});
  c.outPorts.add('error',
    {datatype: 'object'});

  noflo.helpers.WirePattern(c, {
    in: ['in', 'tree', 'repository'],
    params: 'token',
    out: ['graph', 'component', 'spec'],
    async: true
  }
  , function(data, groups, out, callback) {
    if (!data.tree.tree) { return callback(); }
    if (!(data.in.push != null ? data.in.push.length : undefined)) { return callback(); }

    return processTree('', data.tree, data.in.push, data.repository, c.params.token, out, callback);
  });

  return c;
};
