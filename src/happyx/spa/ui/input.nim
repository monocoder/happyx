## # Input Component ✨
## 
## Provides beautiful built-in outlined input component
## 
## > ⚠ Works only with `-d:enableUi` flag ⚠
## 
## 
## ### Params ⚙
## 
## | Name          | Type                       | Required | Default Value                        |
## | :---:         | :---:                      | :---:    | :---:                                |
## | `action`      | `proc(str: cstring): void` |  ❌      | `proc(str: cstring): void = discard` |
## | `placeholder` | `string`                   |  ❌      | `""`                                 |
## | `inputType`   | `string`                   |  ❌      | `""`                                 |
## 
## Input hasn't slot
## 

import
  ../../core/[constants, exceptions],
  ../renderer,
  ../state,
  ../components,
  ./palette


type InputAction* = proc(str: cstring): void

const DefaultInputAction*: InputAction = proc(str: cstring) = discard


component Input:
  # action when any input
  action: InputAction = DefaultInputAction
  placeholder: string = ""
  label: string = ""
  inputType: string = ""

  `template`:
    tDiv:
      tInput(`type` = self.inputType, placeholder = self.placeholder):
        @input(ev):
          {.emit: "console.log(`ev`.data);".}
      tLabel:
        {self.label}
    
  `style`: """
    div {
      position: relative;
      display: flex;
      flex-direction: column;
      justify-content: center;
      width: fit-content;
      height: fit-content;
    }

    input {
      display: flex;
      gap: .5rem;
      flex-direction: row;
      transition: all;
      transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
      transition-duration: .3s;
      border-radius: .3rem;
      padding: .5rem 1rem;
      cursor: pointer;
      user-select: none;
      background: none;
      outline: none;
      border: 2px solid {SecondaryColor};
      color: {ForegroundColor};
    }

    label {
      pointer-events: none;
      position: absolute;
      padding-left: 1rem;
      margin-top: -0.1rem;
      margin-left: 2px;
      transition: all;
      transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
      transition-duration: .15s;
      color: {ForegroundColor};
    }

    input:focus + label, :not(:placeholder-shown) + label {
      transform: translate(0, -1rem);
      font-size: .75rem;
      margin-left: 1rem;
      padding: 0 .5rem;
      background-color: {BackgroundColor};
    }

    input:not(:focus)::placeholder {
      opacity: 0;
    }

    input:hover {
      border: 2px solid {SecondaryHoverColor};
    }

    input:active {
      border: 2px solid {SecondaryActiveColor};
    }

    input:focus {
      border: 2px solid {SecondaryActiveColor};
    }
  """