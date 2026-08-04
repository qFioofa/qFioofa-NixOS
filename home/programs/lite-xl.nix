{ config, pkgs, ... }:

let
  theme = import ../../theme.nix;

  plugins = builtins.fetchGit {
    url = "https://github.com/lite-xl/lite-xl-plugins";
    rev = "ba6bff1de455a65bf4f5a60f04e07ff390911937";
  };

  vimxl = builtins.fetchGit {
    url = "https://github.com/sashabjorkman/vimxl";
    rev = "41d0dd284438a097f44c71f7e4680f0407939457";
  };

  fontPath = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf";

  selectedPlugins = [
    "autosave"
    "autoinsert"
    "indentguide"
    "smoothcaret"
    "bracketmatch"
    "selectionhighlight"
    "rainbowparen"
    "linenumbers"
    "opacity"
    "language_nix"
    "language_sh"
    "language_kdl"
    "minimap"              # мини-карта файла справа
    "sticky_scroll"        # "липкий" заголовок функции при скролле
    "editorconfig"         # уважает .editorconfig (отступы и пр.)
    "togglesnakecamel"     # переключение camelCase/snake_case/kebab-case
    "sort"                 # сортировка строк
    "wordcount"            # счётчик слов в статусбаре
    "colorpreview"         # превью цветов (#hex) прямо в коде
    "smartopenselected"    # открыть файл/путь под курсором (ctrl+shift+alt+p)
    "datetimestamps"       # вставка даты/времени
    "extend_selection_line" # выделение всей строки
    "centerdoc"            # центрирование документа / zen-режим (ctrl+alt+z)
    "markers"              # маркеры TODO/FIXME (ctrl+f2 / f2)
    "unboundedscroll"      # скролл за пределы конца файла
    "statusclock"          # часы в статусбаре
    "autosaveonfocuslost"  # автосохранение при потере фокуса окном
    "force_syntax"         # принудительная смена типа файла
  ];

  dirPlugins = [ "editorconfig" ];
in
{
  home.packages = [ pkgs.lite-xl ];

  xdg.mimeApps.defaultApplications = {
    "text/plain" = "lite-xl.desktop";
  };

  xdg.configFile = {
    "lite-xl/init.lua".text = ''
      -- === Модули ===
      local common = require "core.common"
      local style  = require "core.style"
      local config = require "core.config"
      local core   = require "core"
      local command = require "core.command"

      -- === Шрифт ===
      -- В lite-xl 2.1.8 субпиксельный рендеринг (по умолчанию) даёт артефакты:
      -- цветную кайму/искажённые глифы из-за кастомных весов LCD-фильтра FreeType
      -- (исправлено только в новых версиях, PR lite-xl/lite-xl#2212).
      -- grayscale + full-hinting — надёжная комбинация без артефактов.
      local font_opts = { antialiasing = "grayscale", hinting = "full" }
      local function load_font(path, size)
        return renderer.font.load(path, size, font_opts)
      end

      style.font = load_font("${fontPath}", 14 * SCALE)
      style.big_font = load_font("${fontPath}", 36 * SCALE)
      style.code_font = load_font("${fontPath}", 14 * SCALE)

      -- === Цветовая схема (из theme.nix) ===
      style.background  = { common.color "${theme.bg}" }
      style.background2 = { common.color "${theme.bgSurface}" }
      style.background3 = { common.color "${theme.bgSurface}" }
      style.text        = { common.color "${theme.fg}" }
      style.dim         = { common.color "${theme.fgDim}" }
      style.accent      = { common.color "${theme.primary}" }
      style.error       = { common.color "${theme.error}" }
      style.line_number  = { common.color "${theme.fgMuted}" }
      style.line_number2 = { common.color "${theme.fgDim}" }
      style.selection   = { common.color "${theme.bgSurface}" }
      style.caret       = { common.color "${theme.primary}" }
      style.divider     = { common.color "${theme.bgSurface}" }
      style.line_highlight = { common.color "${theme.bgSurface}" }
      style.scrollbar   = { common.color "${theme.bgSurface}" }
      style.scrollbar2  = { common.color "${theme.fgMuted}" }
      style.scrollbar_track = { common.color "${theme.bg}" }

      style.syntax["comment"]  = { common.color "${theme.fgMuted}" }
      style.syntax["keyword"]  = { common.color "${theme.violet}" }
      style.syntax["keyword2"] = { common.color "${theme.primary}" }
      style.syntax["number"]   = { common.color "${theme.amber}" }
      style.syntax["literal"]  = { common.color "${theme.amber}" }
      style.syntax["string"]   = { common.color "${theme.success}" }
      style.syntax["function"] = { common.color "${theme.primary}" }
      style.syntax["operator"] = { common.color "${theme.fg}" }
      style.syntax["normal"]   = { common.color "${theme.fg}" }
      style.syntax["symbol"]   = { common.color "${theme.fg}" }

      -- === Базовый UX ===
      config.tab_type = "soft"
      config.indent_size = 2
      config.line_height = 1.3

      -- === Режим "1 файл" (Notepad style) ===
      config.plugins.tabbar = false
      config.plugins.treeview = false

      local original_open_doc = core.open_doc
      function core.open_doc(filename)
        if #core.docs > 0 then
          core.error("Разрешён только 1 файл. Закройте текущий (File → Close).")
          return core.docs[1]
        end
        return original_open_doc(filename)
      end

      -- === Настройка плагинов ===
      -- autosave: сохранение через 1 секунду после последнего нажатия
      config.plugins.autosave.enabled = true
      config.plugins.autosave.timeout = 1

      -- indentguide: линии отступов с подсветкой текущего блока
      config.plugins.indentguide.enabled = true
      config.plugins.indentguide.highlight = true

      -- smoothcaret: плавная анимация курсора
      config.plugins.smoothcaret.enabled = true
      config.plugins.smoothcaret.rate = 0.65

      -- linenumbers: гибридные номера строк (абсолютный для текущей, относительные для остальных)
      config.plugins.linenumbers.show = true
      config.plugins.linenumbers.hybrid = true

      -- bracketmatch: подчёркивание парных скобок
      config.plugins.bracketmatch.style = "underline"
      config.plugins.bracketmatch.highlight_both = true

      -- rainbowparen: радужные скобки
      config.plugins.rainbowparen.enabled = true

      -- === Vim (vimxl) ===
      -- VimXL включает вимовские режимы для каждого документа по умолчанию:
      -- старт в normal (Esc → normal), i/a/o — insert, v/V/ctrl+v — visual,
      -- ":" — командная строка (:w, :q, :q!, :e, :bd, :s, :vs).
      -- Нативные вим-бинды: h/j/k/l, w/W/b/e, gg/G, 0/$/^/|, f/F, n/N,
      -- операторы d/c/y/x/p/P/s/S, числа (2d3j), "." — повтор, "u" — undo.
      -- В insert-режиме работают стандартные бинды lite-xl (ctrl+s и т.д.).
      -- Отключить vim для документа: команда "vimxl:toggle-vi-mode"
      -- (или клик по индикатору режима в статусбаре).

      -- Расширяем командный режим ":" вим-нативными командами поверх vimxl.
      -- :wq — сохранить и закрыть (в single-file режиме закрытие = выход).
      local vim_available = require "plugins.vimxl.available-commands"
      local vim_functions = require "plugins.vimxl.functions"
      vim_functions["vimxl-save-and-close"] = function (state)
        command.perform("doc:save", state.view)
        command.perform("vimxl:close-or-quit")
      end
      vim_available["wq"] = "vimxl-save-and-close"

      -- === Настройка UX-плагинов ===
      -- minimap: мини-карта, скрывать для коротких файлов
      config.plugins.minimap.enabled = true
      config.plugins.minimap.avoid_small_docs = true

      -- sticky_scroll: заголовок текущей функции остаётся наверху
      config.plugins.sticky_scroll.enabled = true

      -- centerdoc: центрировать короткие документы (ctrl+alt+z — zen-режим)
      config.plugins.centerdoc.enabled = true

      -- statusclock: часы в статусбаре
      config.plugins.statusclock.enabled = true

      -- editorconfig: применяет .editorconfig автоматически (ничего настраивать не нужно)
    '';
  } // {
    "lite-xl/plugins/vimxl" = { source = vimxl; };
  } // (builtins.listToAttrs (map (name: {
    name = "lite-xl/plugins/${name}" + (if builtins.elem name dirPlugins then "" else ".lua");
    value.source = "${plugins}/plugins/${name}";
  }) selectedPlugins));
}
