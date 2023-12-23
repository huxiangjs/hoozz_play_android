/*
 * MIT License
 *
 * Copyright (c) 2023 Hoozz <huxiangjs@foxmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdio.h>
#include <malloc.h>
#include <pthread.h>
#include <unistd.h>
#include <gitt_ssh.h>
#include <gitt_errno.h>
#include <gitt_log.h>
#include <android/log.h>

struct gitt_ssh {
	int ssh_id;
};

struct gitt_ssh_daemon {
	pthread_mutex_t mutex1;
	pthread_mutex_t mutex2;
	int type;
	int ssh_id;
	char *buff;
	int length;
	int retval;
};

/* Note: Currently only single-threaded SSH is supported */
static struct gitt_ssh_daemon ssh_daemon;

#define SSH_CMD_TYPE_CONNECT		0
#define SSH_CMD_TYPE_READ		1
#define SSH_CMD_TYPE_WRITE		2
#define SSH_CMD_TYPE_DISCONNECT		3
#define SSH_CMD_TYPE_ERROR		-1

/*
 * This function needs to be called asynchronously on dart
 * and called repeatedly when the return value is not -1
 */
int gitt_ssh_daemon_wait(int *ssh_id, char **buff, int *size)
{
	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	pthread_mutex_lock(&ssh_daemon.mutex1);
	*ssh_id = ssh_daemon.ssh_id;
	*buff = ssh_daemon.buff;
	*size = ssh_daemon.length;

	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	return ssh_daemon.type;
}

/*
 * After dart is processed, this function will be called to write the data back.
 */
void gitt_ssh_daemon_write(int ret, int ssh_id, int size)
{
	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	ssh_daemon.retval = ret;
	ssh_daemon.ssh_id = ssh_id;
	ssh_daemon.length = size;

	pthread_mutex_unlock(&ssh_daemon.mutex2);

	gitt_log_debug("%s:%d\n", __func__, __LINE__);
}

void gitt_ssh_daemon_init(void)
{
	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	pthread_mutex_init(&ssh_daemon.mutex1, NULL);
	pthread_mutex_init(&ssh_daemon.mutex2, NULL);
	pthread_mutex_lock(&ssh_daemon.mutex1);
	pthread_mutex_lock(&ssh_daemon.mutex2);
}

void gitt_ssh_daemon_deinit(void)
{
	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	ssh_daemon.type = SSH_CMD_TYPE_ERROR;
	pthread_mutex_unlock(&ssh_daemon.mutex1);
	pthread_mutex_lock(&ssh_daemon.mutex2);

	pthread_mutex_unlock(&ssh_daemon.mutex2);
	pthread_mutex_unlock(&ssh_daemon.mutex1);
	pthread_mutex_destroy(&ssh_daemon.mutex2);
	pthread_mutex_destroy(&ssh_daemon.mutex1);
}

struct gitt_ssh* gitt_ssh_alloc_impl(void)
{
	return (struct gitt_ssh *)malloc(sizeof(struct gitt_ssh));
}

void gitt_ssh_free_impl(struct gitt_ssh *ssh)
{
	free(ssh);
}

int gitt_ssh_connect_impl(struct gitt_ssh *ssh, struct gitt_ssh_url *ssh_url,
			  const char *exec, const char *privkey)
{
	char buff[2048];
	int ret;

	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	ret = snprintf(buff, sizeof(buff), "%s;%s;%s;%s;%s", ssh_url->user,
		       ssh_url->host, ssh_url->port, exec, privkey);

	ssh_daemon.type = SSH_CMD_TYPE_CONNECT;
	ssh_daemon.buff = buff;
	ssh_daemon.length = ret;

	pthread_mutex_unlock(&ssh_daemon.mutex1);
	pthread_mutex_lock(&ssh_daemon.mutex2);

	ssh->ssh_id = ssh_daemon.ssh_id;
	gitt_log_debug("connect retval = %d\n", ssh_daemon.retval);

	return ssh_daemon.retval;
}

int gitt_ssh_read_impl(struct gitt_ssh *ssh, char *buf, int size)
{
	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	ssh_daemon.type = SSH_CMD_TYPE_READ;
	ssh_daemon.ssh_id = ssh->ssh_id;
	ssh_daemon.buff = buf;
	ssh_daemon.length = size;

	pthread_mutex_unlock(&ssh_daemon.mutex1);
	pthread_mutex_lock(&ssh_daemon.mutex2);

	gitt_log_debug("read size: %d, retval = %d\n", size, ssh_daemon.retval);

	return ssh_daemon.retval;
}

int gitt_ssh_write_impl(struct gitt_ssh *ssh, char *buf, int size)
{
	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	ssh_daemon.type = SSH_CMD_TYPE_WRITE;
	ssh_daemon.ssh_id = ssh->ssh_id;
	ssh_daemon.buff = buf;
	ssh_daemon.length = size;

	pthread_mutex_unlock(&ssh_daemon.mutex1);
	pthread_mutex_lock(&ssh_daemon.mutex2);

	gitt_log_debug("write size: %d, retval = %d\n", size, ssh_daemon.retval);

	return ssh_daemon.retval;
}

void gitt_ssh_disconnect_impl(struct gitt_ssh *ssh)
{
	gitt_log_debug("%s:%d\n", __func__, __LINE__);

	ssh_daemon.type = SSH_CMD_TYPE_DISCONNECT;
	ssh_daemon.ssh_id = ssh->ssh_id;
	pthread_mutex_unlock(&ssh_daemon.mutex1);
	pthread_mutex_lock(&ssh_daemon.mutex2);
}
