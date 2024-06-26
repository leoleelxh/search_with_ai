<template>
  <div id="search" class="relative size-full">
    <div class="absolute inset-0 overflow-hidden rounded-2xl bg-gray-100 p-2 dark:bg-zinc-900">
      <div ref="wrapperRef" class="h-full overflow-y-auto rounded-2xl bg-white dark:bg-zinc-800">
        <div class="p-4">
          <div class="flex flex-nowrap items-center justify-between border-0 border-b border-solid border-gray-100 pb-4 dark:border-black">
            <div class="inline-flex text-xl font-bold leading-8 text-blue-800 dark:text-blue-200">{{ query }}</div>
            <div class="flex w-14 grow-0 justify-end">
              <t-button :disabled="loading" theme="default" shape="circle" @click="onReload">
                <template #icon><RiRestartLine /></template>
              </t-button>
            </div>
          </div>
          <div class="mt-4">
            <div class="flex flex-nowrap items-center gap-2 py-4 text-black dark:text-gray-200">
              <RiQuestionAnswerLine />
              <span class="text-lg font-bold ">AI回答</span>
            </div>
            <ChatAnswer :answer="result?.answer" :contexts="result?.contexts" />
          </div>
          <div class="mt-4">
            <div class="flex flex-nowrap items-center gap-2 py-4 text-black dark:text-gray-200">
              <RiBook2Line />
              <span class="text-lg font-bold ">参考资料</span>
            </div>
            <ChatSources :loading="loading" :sources="result?.contexts" />
          </div>
          <div class="mt-4">
            <div class="flex flex-nowrap items-center gap-2 py-4 text-black dark:text-gray-200">
              <RiChatQuoteLine />
              <span class="text-lg font-bold ">相关问题</span>
            </div>
            <RelatedQuery :related="result?.related" @select="onSelectQuery" />
          </div>
          <div class="mt-4 pb-20">
            <PageFooter />
          </div>
        </div>
      </div>
      <div class="absolute inset-x-6 bottom-6 flex items-center justify-center">
        <div class="w-full  rounded-3xl drop-shadow-2xl">
          <SearchInputBar :loading="loading" @search="onSearch" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { MessagePlugin } from 'tdesign-vue-next';
import { useAppStore } from '../store';
import { RiQuestionAnswerLine, RiBook2Line, RiChatQuoteLine, RiRestartLine } from '@remixicon/vue';
import router from '../router';
import { search } from '../api';
import { PageFooter, ChatAnswer, RelatedQuery, ChatSources, SearchInputBar } from '../components';
import { IQueryResult } from '../interface';

const wrapperRef = ref<HTMLDivElement | null>(null);
const appStore = useAppStore();

const keyword = computed(() => router.currentRoute.value.query.q ?? '');
const query = ref<string>('');
const loading = ref(false);
let abortCtrl: AbortController | null = null;

const result = ref<IQueryResult>({
  related: '',
  answer: '',
  contexts: []
});

const onSelectQuery = (val: string) => {
  query.value = val;
  querySearch(val);
};

const onSearch = (val: string) => {
  query.value = val;
  router.currentRoute.value.query.q ??= val;
  querySearch(val);
}; 

const onReload = () => {
  querySearch(query.value);
};

onMounted(() => {
  query.value = keyword.value as string;
  querySearch(query.value);
});

async function querySearch(val: string | null) {
  if (!val) return;
  clear();
  replaceQueryParam('q', val);
  if (abortCtrl) {
    abortCtrl.abort();
    abortCtrl = null;
  }
  const ctrl = new AbortController();
  abortCtrl = ctrl;
  try {
    loading.value = true;
    const { model, engine } = appStore;
    await search(val, {
      model: model?.split(':')[1],
      engine,
      ctrl,
      onMessage: (data: any) => {
        // if (wrapperRef.value) wrapperRef.value.scrollTop = wrapperRef.value.scrollHeight
        if (data?.context) {
          result.value.contexts?.push(data.context);
        }
        if (data?.answer) {
          result.value.answer += data.answer;
        }
        if (data?.related) {
          result.value.related += data.related;
        }
      },
      onClose: () => {
        console.log('closed');
        abortCtrl = null;
        loading.value = false;
      },
      onError: (err) => {
        console.log('error', err);
        MessagePlugin.error(`查询出现错误: ${err.message}`);
        loading.value = false;
      }
    });
  } catch(err) {
    ctrl.abort();
    abortCtrl = null;
    console.log(err);
    loading.value = false;
    MessagePlugin.error('查询失败了');
  }
}

function clear () {
  result.value = {
    related: '',
    answer: '',
    contexts: []
  };
}

function replaceQueryParam(name: string, val: string) {
  const url = new URL(location.href);
  url.searchParams.set(name, val);
  history.replaceState({}, '', url.toString());
}
</script>

<script lang="ts">
export default {
  name: 'SearchPage'
};
</script>
