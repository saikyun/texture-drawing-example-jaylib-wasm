(def out-dir "public")

(def port "8000")

(def preload-dir "resources")

###########################################################################

(def start (os/clock))

(unless (os/getenv "EMSDK")
  (eprintf "emsdk environment not detected: try source emsdk_env.sh?")
  (os/exit 1))

(prinf "\n[ensuring existence of directory: %p]..." out-dir)
(try
  (os/mkdir out-dir)
  ([e]
    (eprintf "<<problem with mkdir for: %p>>" out-dir)
    (os/exit 1)))

(unless (os/getenv "JAYLIB_WASM_DEMO_SKIP_DEPS")
  #
  (printf "\n[preparing amalgamated janet.c and related]...")
  (let [old-dir (os/cwd)]
    (try
      (os/cd "janet")
      ([e]
        (eprintf "<<failed to cd to janet directory>>")
        (os/exit 1)))
    (try
      (os/execute ["make" "clean"] :px)
      ([e]
        (eprintf "<<problem with make clean for janet>>")
        (os/exit 1)))
    (try
      (os/execute ["make"] :px)
      ([e]
        (eprintf "<<problem making janet>>")
        (os/exit 1)))
    (try
      (os/cd old-dir)
      ([e]
        (eprintf "<<problem restoring current directory>>")
        (os/exit 1))))
  #
  (printf "\n[preparing HTML5-aware libraylib.a]...")
  (let [old-dir (os/cwd)]
    (try
      (os/cd "jaylib/raylib/src")
      ([e]
        (eprintf "<<failed to cd to jaylib directory>>")
        (os/exit 1)))
    (try
      (os/execute ["make" "clean"] :px)
      ([e]
        (eprintf "<<problem with make clean for raylib>>")
        (os/exit 1)))
    (try
      (os/execute ["make"
                   # XXX: causing emcc to fail at last step?
                   #"CFLAGS=-gsource-map"
                   "PLATFORM=PLATFORM_WEB" "-B" "-e"] :px)
      ([e]
        (eprintf "<<problem building libjaylib.a>>")
        (os/exit 1)))
    (try
      (os/cd old-dir)
      ([e]
        (eprintf "<<problem restoring current directory>>")
        (os/exit 1))))
  #
  (printf "\n[preparing jaylib.janet shim]...")
  (try
    (os/execute ["janet"
                 "make-jaylib-janet-shim.janet"
                 "jaylib/src"
                 (string preload-dir "/jaylib.janet")] :px)
    ([e]
      (eprintf "<<problem creating jaylib.janet shim>>")
      (os/exit 1))))

(printf "\n[copying logo into place]...")
(try
  (spit (string out-dir "/jaylib-logo.png")
        (slurp "jaylib-logo.png"))
  ([e]
    (eprintf "<<problem copying logo>>"
             (os/exit 1))))

(printf "\n[compiling with emcc]...")
(try
  (os/execute ["emcc"
               #"-v"
               "-Wall"
               # debugging
               "-g3"
               #"-gsource-map"
               "-DPLATFORM_WEB"
               "-o" (string out-dir "/main.html")
               "main.c"
               "janet/build/c/janet.c"
               "jaylib/raylib/src/libraylib.a"
               "-Ijanet/build"
               "-Ijaylib/src"
               "-Ijaylib/raylib/src"
               "--preload-file" preload-dir
               "--source-map-base" (string "http://localhost:" port "/")
               "--shell-file" "shell.html"
               # -O0 for dev, -Os for non-ASYNCIFY, -O3 for ASYNCIFY
               "-O0"
               #"-Os"
               #"-O3" "-s" "ASYNCIFY"
               "-s" "ASSERTIONS=2"
               "-s" "ALLOW_MEMORY_GROWTH=1"
               "-s" "FORCE_FILESYSTEM=1"
               "-s" "USE_GLFW=3"
               "-s" `EXPORTED_RUNTIME_METHODS=['cwrap']`
               "-s" "AGGRESSIVE_VARIABLE_ELIMINATION=1"
               #"-s" "MINIFY_HTML=0"
               ]
              :px)
  ([e]
    (eprintf "<<problem compiling with emcc>>")
    (os/exit 1)))
(print)

(def end (os/clock))

(printf "Completed in %p seconds" (- end start))

