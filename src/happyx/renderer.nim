## # Renderer
## 
## Provides a single-page application (SPA) renderer with reactivity features.
## It likely contains functions or classes that allow developers to
## dynamically update the content of a web page without reloading the entire page.

import
  macros,
  logging,
  htmlgen,
  strtabs,
  sugar,
  strutils,
  strformat,
  regex,
  ./tag

export
  strformat,
  logging,
  htmlgen,
  strtabs,
  sugar,
  tag


type
  Renderer* = object
    appId*: string


func newRenderer*(appId: string): Renderer =
  ## Creates a new renderer
  result = Renderer(
    appId: appId
  )


proc replaceIter*(
    root: NimNode,
    search: proc(x: NimNode): bool,
    replace: proc(x: NimNode): NimNode
): bool =
  result = false
  for i in 0..root.len-1:
    result = root[i].replaceIter(search, replace)
    if search(root[i]):
      root[i] = replace(root[i])
      result = true


proc buildHtmlProcedure*(root: NimNode, body: NimNode): NimNode {.compileTime.} =
  ## Builds HTML
  result = newCall("initTag", newStrLitNode($root))

  for statement in body:
    echo statement.kind

    if statement.kind == nnkCall:
      let
        tagName = newStrLitNode($statement[0])
        statementList = statement[^1]
      var attrs = newNimNode(nnkTableConstr)
      # tag(attr="value"):
      #   ...
      if statement.len-2 > 0 and statementList.kind == nnkStmtList:
        for attr in statement[1 .. statement.len-2]:
          attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
        var builded = buildHtmlProcedure(tagName, statementList)
        builded.insert(2, newCall("newStringTable", attrs))
        result.add(builded)
      # tag(attr="value")
      elif statementList.kind != nnkStmtList:
        for attr in statement[1 .. statement.len-1]:
          attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
        if attrs.len > 0:
          result.add(newCall("initTag", tagName, newCall("newStringTable", attrs)))
        else:
          result.add(newCall("initTag", tagName))
      # tag:
      #   ...
      else:
        result.add(buildHtmlProcedure(tagName, statementList))
    
    elif statement.kind == nnkStrLit:
      # "Raw text"
      result.add(newCall("initTag", statement, newLit(true)))
    
    elif statement.kind == nnkIdent:
      # tag
      result.add(newCall("tag", newStrLitNode($statement)))
    
    # if a:
    #   ...
    # else:
    #   ...
    elif statement.kind == nnkIfStmt:
      var ifExpr = newNimNode(nnkIfExpr)
      for branch in statement:
        if branch.kind == nnkElifBranch:
          let
            r = buildHtmlProcedure(ident("div"), branch[1])
            elifExpr = newNimNode(nnkElifExpr).add(branch[0])
          for i in r[2..^1]:
            if i.kind == nnkCall and $i[0] == "@":
              for j in i[1]:
                elifExpr.add(j)
            else:
              elifExpr.add(i)
          ifExpr.add(elifExpr)
        else:
          let
            r = buildHtmlProcedure(ident("div"), branch[0])
            elseExpr = newNimNode(nnkElseExpr)
          for i in r[2..^1]:
            if i.kind == nnkCall and $i[0] == "@":
              for j in i[1]:
                elseExpr.add(j)
            else:
              elseExpr.add(i)
          ifExpr.add(elseExpr)
      if ifExpr.len == 1:
        ifExpr.add(newNimNode(nnkElseExpr).add(
          newCall("tag", newStrLitNode("div"))
        ))
      result.add(ifExpr)
    
    # for ... in ...:
    #   ...
    elif statement.kind == nnkForStmt:
      let
        arguments = collect(newSeq):
          for i in statement[0..statement.len-3]:
            $i
        pattern = re("\\{(" & arguments.join("|") & ")\\}")
      var matches: RegexMatch
      # nnkCall
      var replaced = statement[^1].replaceIter(
        (x) => x.kind == nnkCall and $x[0] in arguments,
        proc(x: NimNode): NimNode =
          let stmtList = x[^1]
          var
            builded: NimNode
            attrs = newNimNode(nnkTableConstr)
          if stmtList.kind == nnkStmtList:
            builded = buildHtmlProcedure(x[0], x[^1])
            # tag(attr="value"):
            #   ...
            for attr in x[1 .. x.len-2]:
              attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
          else:
            builded = buildHtmlProcedure(x[0], newStmtList())
            # tag(attr="value"):
            #   ...
            for attr in x[1 .. x.len-1]:
              attrs.add(newColonExpr(newStrLitNode($attr[0]), attr[1]))
          builded.insert(2, newCall("newStringTable", attrs))
          newNimNode(nnkIfExpr).add(
            newNimNode(nnkElifExpr).add(
              newCall("is", newCall("typeof", x[0]), ident("string")),
              builded
            )
          )
      )
      if not replaced:
        # nnkIdent
        replaced = statement[^1].replaceIter(
          (x) => x.kind == nnkIdent and $x in arguments,
          (x) => newNimNode(nnkIfExpr).add(
            newNimNode(nnkElifExpr).add(
              newCall("is", newCall("typeof", x), ident("string")),
              newCall("initTag", x)
            )
          )
        )
      # nnkStrLit with {}
      discard statement[^1].replaceIter(
        (x) => x.kind == nnkStrLit and ($x).find(pattern, matches),
        (x) => newCall("fmt", x)
      )
      result.add(
        newCall(
          "initTag",
          newStrLitNode("div"),
          newCall(
            "collect",
            ident("newSeq"),
            newNimNode(nnkStmtList).add(statement)
          )
        )
      )
  
  # varargs -> seq
  if result.len > 2:
    if result[2].kind == nnkCall and $result[2][0] == "newStringTable":
      var
        tagRefs = result[3..result.len-1]
        arr = newNimNode(nnkBracket)
      result.del(3, result.len - 3)
      for tag in tagRefs:
        arr.add(tag)
      result.add(newCall("@", arr))
    else:
      var
        tagRefs = result[2..result.len-1]
        arr = newNimNode(nnkBracket)
      result.del(2, result.len - 2)
      for tag in tagRefs:
        arr.add(tag)
      result.add(newCall("@", arr))


macro buildHtml*(root, html: untyped): untyped =
  ## `buildHtml` macro provides building HTML tags with YAML-like syntax.
  ## 
  ## Args:
  ## - `root`: root element. It's can be `tag`, tag or tTag
  ## - `html`: YAML-like structure.
  ## 
  ## Syntax support:
  ##   - attributes via exprEqExpr
  ##   
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          h1(class="myClass", align="center")
  ##          input(`type`="password", align="center")
  ##   
  ##   - nested tags
  ##   
  ##     .. code-block:: nim
  ##        echo buildHtml(`div`):
  ##          tag:
  ##            tag1:
  ##              tag2:
  ##            tag1withattrs(attr="value")
  ##   
  ##   - if-elif-else expressions
  ## 
  ##     .. code-block:: nim
  ##        var state = true
  ##        echo buildHtml(`div`):
  ##          if state:
  ##            "True!"
  ##          else:
  ##            "False("
  ##   
  ##   - for statements
  ## 
  ##     .. code-block:: nim
  ##        var state = @["h1", "h2", "input"]
  ##        echo buildHtml(`div`):
  ##          for i in state:
  ##            i
  ## 
  result = buildHtmlProcedure(root, html)
  echo treeRepr result