// This is an input file that can be used to generate dart files through tools.
// For details, please see: ffigen.yaml

int remote_sw_init(char *repository, char *privkey);
int remote_sw_press(void);
int remote_sw_result(int timeout);
int remote_sw_report(void);

int gitt_ssh_daemon_wait(int *ssh_id, char **buff, int *size);
void gitt_ssh_daemon_write(int ret, int ssh_id, int size);
void gitt_ssh_daemon_init(void);
void gitt_ssh_daemon_deinit(void);
