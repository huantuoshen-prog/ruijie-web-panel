import { act, cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { afterEach, expect, it, vi } from 'vitest';
import App from './App';

afterEach(() => { cleanup(); vi.restoreAllMocks(); vi.unstubAllGlobals(); });

function setup() {
  let poll: (() => void) | undefined;
  vi.spyOn(window, 'setInterval').mockImplementation(((fn: () => void, ms: number) => {
    if (ms === 15000) poll = fn;
    return 123;
  }) as typeof window.setInterval);
  const data: Record<string, unknown> = {
    auth: {success:true, authenticated:true},
    status: {installed:true, online:true, username:'saved-user', operator:'DianXin',account_type:'student',daemon_running:true,version:'3.1'},
    account: {username:'saved-user',operator:'DianXin',account_type:'student'},
    settings: {proxy_url:'',proxy_url_https:''},
    health: {supported:false,message:'mock unsupported'},
    runtime: {supported:false},
    log: {lines:[],total:0}
  };
  vi.stubGlobal('fetch', vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const key = String(input).split('/').pop()!.split('?')[0];
    const body = init?.method === 'POST' ? {success:false,message:'mock write failed'} : data[key];
    return new Response(JSON.stringify(body), {status:200,headers:{'Content-Type':'application/json'}});
  }));
  render(<App />);
  return () => poll?.();
}

it('keeps unsaved username while background polling refreshes status', async () => {
  const poll = setup();
  await screen.findByRole('heading', {name:'总览',level:2});
  fireEvent.click(screen.getByRole('button',{name:'账号 认证账号与网络配置'}));
  const input = screen.getByRole('textbox',{name:'用户名'});
  await waitFor(() => expect(input).toHaveValue('saved-user'));
  fireEvent.change(input,{target:{value:'unsaved-user'}});
  expect(input).toHaveValue('unsaved-user');
  await act(async () => { poll(); });
  await waitFor(() => expect(input).toHaveValue('unsaved-user'));
});

it('keeps password and reports an error when a business write fails', async () => {
  setup();
  await screen.findByRole('heading', {name:'总览',level:2});
  fireEvent.click(screen.getByRole('button',{name:'账号 认证账号与网络配置'}));
  await waitFor(() => expect(screen.getByRole('textbox',{name:'用户名'})).toHaveValue('saved-user'));
  const password = screen.getByLabelText('密码');
  fireEvent.change(password,{target:{value:'test-password'}});
  fireEvent.click(screen.getByRole('button',{name:'保存账号配置'}));
  const msg=await screen.findByText('mock write failed');
  expect(msg.closest('[class*="error"]')).not.toBeNull();
  expect(password).toHaveValue('test-password');
});
