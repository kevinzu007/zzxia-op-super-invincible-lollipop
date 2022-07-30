FROM fluent/fluentd:v1.11.2-1.0
USER root
RUN ["gem", "install", "fluent-plugin-elasticsearch", "--no-document"]
RUN ["gem", "install", "fluent-plugin-forest", "--no-document"]
RUN ["gem", "install", "fluent-plugin-record-reformer", "--no-document"]
RUN ["gem", "install", "fluent-plugin-rewrite-tag-filter", "--no-document"]
RUN ["gem", "install", "fluent-plugin-grep", "--no-document"]
RUN ["gem", "install", "fluent-plugin-record-modifier", "--no-document"]
USER fluent


