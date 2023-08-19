# Import HappyX
import
  ../../../../src/happyx,
  ../ui/colors,
  ./[button, drawer],
  regex,
  unicode,
  macros,
  json,
  os


var
  currentGuidePage* = remember "introduction"
  guidePages* = %*{
    "introduction": {
      "title": "Introduction ✌",
      "prev": "",
      "next": "getting_started"
    },
    "getting_started": {
      "title": "Getting Started 💫",
      "prev": "introduction",
      "next": "happyx_app"
    },
    "happyx_app": {
      "title": "HappyX Application 🍍",
      "prev": "getting_started",
      "next": ""
    }
  }


component SideBarTitle:
  `template`:
    tP(class = "text-7xl lg:text-2xl xl:text-xl font-bold cursor-pointer select-none"):
      slot


component SideBarFolder:
  `template`:
    tP(class = "text-5xl lg:text-xl xl:text-lg font-bold cursor-pointer select-none pl-2"):
      slot


component SideBarItem:
  id: string
  `template`:
    tP(
      class =
        if currentGuidePage.val == self.id:
          fmt"pl-12 lg:pl-8 xl:pl-4 text-4xl lg:text-lg xl:text-base cursor-pointer select-none bg-[{Foreground}]/25 dark:bg-[{ForegroundDark}]/25"
        else:
          "pl-12 lg:pl-8 xl:pl-4 text-4xl lg:text-lg xl:text-base cursor-pointer select-none"
    ):
      slot
      @click:
        route(fmt"/guide/{self.SideBarItem.id}")


# Declare component
component SideBar:
  isMobile: bool = false

  # Declare HTML template
  `template`:
    tDiv(class =
        if self.isMobile:
          "flex-col xl:flex gap-12 lg:gap-8 xl:gap-4 px-2 h-full"
        else:
          "flex-col hidden xl:flex gap-12 lg:gap-8 xl:gap-4 px-2 pt-8 h-full"
    ):
      if not self.isMobile:
        tP(class = "text-5xl lg:text-3xl xl:text-2xl font-bold text-center w-max"):
          "Documentation 📕"
      tDiv(class = "flex flex-col justify-between gap-16 lg:gap-12 xl:gap-8"):
        tDiv(class = "flex flex-col pl-8 lg:pl-6 xl:pl-4 gap-8 lg:gap-4 xl:gap-2"):
          component SideBarTitle:
            "User Guide 📖"
            component SideBarFolder:
              "General 🍍"
              component SideBarItem("introduction"):
                "Introduction ✌"
              component SideBarItem("getting_started"):
                "Getting Started 💫"
            component SideBarFolder:
              "Basics 📖"
              component SideBarItem("happyx_app"):
                "HappyX Application 🍍"
        tDiv(class = "flex"):
          component Button(
            action = proc() =
              {.emit: """//js
              window.open('https://hapticx.github.io/happyx/happyx.html', '_blank').focus();
              """.}
          ):
            "📕 API Docs"