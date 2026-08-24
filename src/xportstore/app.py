import toga
from toga.style import Pack
from toga.style.pack import COLUMN


APP_URL = "https://xportstore.ru/"


class XportStore(toga.App):
    def startup(self):
        content = toga.Box(style=Pack(direction=COLUMN))
        self.web = toga.WebView(style=Pack(flex=1), url=APP_URL)
        content.add(self.web)

        self.main_window = toga.MainWindow(title="XPort Store")
        self.main_window.content = content
        self.main_window.show()


def main():
    return XportStore(
        "XPort Store",
        "ru.xportstore",
        author="X-Port",
        home_page=APP_URL,
    )
