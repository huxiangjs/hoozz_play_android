#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <pwd.h>
#include <gitt.h>
#include <gitt_errno.h>
#include <gitt_type.h>
#include <android/log.h>

#define LOG_TAG "REMOTE SW"

#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

struct remote_sw_gitt {
	struct gitt g;
	char *home;
	char privkey[2048];
	char repository[64];
	uint8_t buffer[4096];
	char result[32];
};

#define DEVICE_NAME			"Android Device"
#define DEVICE_ID			"0000000000000002"

struct remote_sw_gitt rgitt;

static int gitt_get_date_impl(char *buf, uint8_t size)
{
	time_t cur_time;

	cur_time = time(NULL);
	if (cur_time == -1)
		return cur_time;

	sprintf(buf, "%ld", cur_time);

	return 0;
}

static int gitt_get_zone_impl(char *buf, uint8_t size)
{
	int h, m;
	char d;
	long zone;

	tzset();

	zone = timezone / -60;
	d = zone < 0 ? '-' : '+';
	h = zone / 60;
	m = zone % 60;

	sprintf(buf, "%c%02d%02d", d, h, m);

	return 0;
}

static void gitt_replace(char src, char tag, char *buf, int buf_size)
{
	int i;

	for (i = 0; i < buf_size; i++)
		buf[i] = buf[i] == src ? tag : buf[i];
}

static void gitt_remote_event_callback(struct gitt *g, struct gitt_device *device,
				       char *date, char *zone, char *event)
{
	struct remote_sw_gitt *rgitt = gitt_containerof(g, struct remote_sw_gitt, g);
	gitt_replace('\n', ' ', event, strlen(event));
	strncpy(rgitt->result, event, sizeof(rgitt->result));
}

int remote_sw_init(char *repository, char *privkey)
{
	int ret;

	if (!repository || !privkey) {
		LOGI("Neither repository nor privkey can be empty\n");
		return -1;
	}

	strncpy(rgitt.repository, repository, sizeof(rgitt.repository));
	strncpy(rgitt.privkey, privkey, sizeof(rgitt.privkey));
	LOGI("Repository: %s\n", rgitt.repository);

	/* Initialize */
	rgitt.g.privkey = rgitt.privkey;
	rgitt.g.url = rgitt.repository;
	rgitt.g.buf = rgitt.buffer;
	rgitt.g.buf_len = sizeof(rgitt.buffer);
	rgitt.g.remote_event = gitt_remote_event_callback;

	/* These two functions are optional, you can choose not to implement them */
	rgitt.g.get_date = gitt_get_date_impl;
	rgitt.g.get_zone = gitt_get_zone_impl;

	LOGI("Initialize...\n");
	ret = gitt_init(&rgitt.g);
	LOGI("Initialize result: %s\n", GITT_ERRNO_STR(ret));
	if (ret)
		return ret;

	LOGI("HEAD: %s\n", rgitt.g.repository.head);
	LOGI("Refs: %s\n", rgitt.g.repository.refs);

	/* Set device info */
	strcpy(rgitt.g.device.name, DEVICE_NAME);
	strcpy(rgitt.g.device.id, DEVICE_ID);
	LOGI("Device name: %s\n", rgitt.g.device.name);
	LOGI("Device id:   %s\n", rgitt.g.device.id);

	return 0;
}

int remote_sw_press(void)
{
	int ret;

	LOGI("Please wait...\n");
	ret = gitt_commit_event(&rgitt.g, "PRESS");
	LOGI("Commit event result: %s\n", GITT_ERRNO_STR(ret));
	if (ret)
		return -1;

	return 0;
}

/**
 * @brief
 *
 * @param timeout
 * @return int -1: fail or timeout
 * @return int  1: on
 * @return int  0: off
 */
int remote_sw_result(int timeout)
{
	int ret;
	time_t cur_time;
	time_t out_time;

	cur_time = time(NULL);
	out_time = cur_time + timeout;
	LOGI("Time: %ld -> %ld\n", cur_time, out_time);

	while (cur_time < out_time) {
		rgitt.result[0] = '\0';
		ret = gitt_update_event(&rgitt.g);
		LOGI("Update event result: %s [%ld/%ld]\n", GITT_ERRNO_STR(ret), cur_time, out_time);
		if (ret)
			break;
		/* Wait done */
		if (!memcmp(rgitt.result, "STATE ", 6)) {
			LOGI("Got it! State: %s\n", rgitt.result + 6);
			if (!memcmp(rgitt.result + 6, "ON", 2))
				return 1;
			else
				return 0;
		}
		sleep(1);

		cur_time = time(NULL);
	}

	return -1;
}

int remote_sw_report(void)
{
	int ret;

	LOGI("Please wait...\n");
	ret = gitt_commit_event(&rgitt.g, "REPORT");
	LOGI("Commit event result: %s\n", GITT_ERRNO_STR(ret));
	if (ret)
		return -1;

	return 0;
}
