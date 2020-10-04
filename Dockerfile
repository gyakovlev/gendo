# syntax = docker/dockerfile:experimental
FROM gentoo/portage AS portage
FROM gentoo/stage3 AS stage3
ENV FEATURES="-cgroup -sandbox -usersandbox -ipc-sandbox -pid-sandbox"
RUN \
 --mount=type=tmpfs,target=/var/tmp/portage \
 --mount=type=bind,from=portage,source=/var/db/repos/gentoo,target=/var/db/repos/gentoo,rw \
 echo '*/* bindist' >> /etc/portage/package.use/bindist \
 && emerge \
  --update --deep --newuse --complete-graph --implicit-system-deps=y \
  --with-bdeps=y --changed-deps=y --dynamic-deps=y \
  --verbose --quiet-build --jobs=4 --oneshot @world \
 && emerge --depclean

FROM scratch
COPY --from=stage3 / /
