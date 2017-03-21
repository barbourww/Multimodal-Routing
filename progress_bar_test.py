__author__ = 'wbarbour1'

import sys
import time


class progress_bar:
    def __init__(self, length):
        self.length = length
        self.last_update = None
        self.last_progress = 0.0
        self.running_dt_dp = 0.0

    def update_progress(self, progress, est_time=False, aux_message=''):
        """
        Prints progress bar to the terminal representing "percent complete"
        :param progress: float [0, 1] representing percentage complete; negative value will display as "halt"
        :param est_time: flag for outputting estimated time of completion based on incremental
        :param aux_message: message from program to terminal, to be printed before progress bar
        :return: None
        """
        bar_length = self.length     # Modify this to change the length of the progress bar
        status = ""
        if isinstance(progress, int):
            progress = float(progress)
        if est_time:
            if self.last_update is not None:
                dt = time.time() - self.last_update     # seconds
                dp = progress - self.last_progress      # %
                self.running_dt_dp = (self.running_dt_dp * self.last_progress + dt) / progress
                eta = (1.0 - progress) * self.running_dt_dp
                self.last_update = time.time()
                self.last_progress = progress
                status += "Approx. "
                status += str(int(eta // 60.)) + ' min, '
                status += str(int(eta % 60.)) + ' sec'
            else:
                self.last_update = time.time()
        if not isinstance(progress, float):
            progress = 0
            status = "error: progress var must be float\r\n"
        if progress < 0:
            progress = 0
            status = "Halt...\r\n"
        if progress >= 1:
            progress = 1
            status = "Done..."
            self.last_update = None
        block = int(round(bar_length * progress))
        if aux_message:
            print aux_message
        text = "\rPercent: [{0}] {1}% {2}".format("#"*block + "-"*(bar_length - block), round(progress*100, 3), status)
        sys.stdout.write(text)
        sys.stdout.flush()

    def test(self):
        print "Initializing test."
        for i in range(101):
            time.sleep(0.05)
            self.update_progress(i / 100.0)
        print ""
        print "Test completed"
