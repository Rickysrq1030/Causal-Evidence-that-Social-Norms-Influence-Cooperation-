# Causal Evidence that Social Norms Influence Cooperation
## Simulation Code

All numerical simulations were performed in MATLAB (R2026a). The source code is organized into modular scripts corresponding to the figures presented in the main text and supplementary material.

### Software Requirements and Execution
To ensure reproducibility, the following environment settings are required:

- **Software:** MATLAB R2023b or higher.
- **Function Dependency:** Every simulation script relies on the standalone function `generate_pop_distribution.m`. This file must be located in the same working directory as the scripts.
- **Parallel Computing:** While scripts are written for serial execution, the `iterations` loops can be converted to `parfor` if the Parallel Computing Toolbox is available.

### Script Catalog
The following table describes the MATLAB scripts included in the supplementary repository:

| File Name | Associated Figure | Simulation Goal |
| :--- | :--- | :--- |
| `SM_Figure_1.m` | SM Fig. 1 | Visualizes population distribution types. |
| `SM_Figure_2.m` | SM Fig. 2 | Comparative steady-states for all γ types. |
| `SM_Figure_3.m` | SM Fig. 3 | Sensitivity analysis of Decision Intensity (β). |
| `Main_Figure_1.m` | Main Fig. 1 | Social Payoff (π<sup>social</sup>) parameter sweep. |
| `Main_Figure_2.m` | Main Fig. 2 | Temporal trajectories and convergence paths. |
| `Main_Figure_3.m` | Main Fig. 3 | Basin of attraction and initial state sensitivity. |

*Description of the MATLAB scripts and their corresponding roles in the study.*

### Data Processing Logic
Each script implements a consistent logic flow:

1.  **Initialization:** Invokes `generate_pop_distribution` to create *N* agent-specific thresholds.
2.  **Iterative Simulation:** Executes 3,000 generations across 500 independent iterations.
3.  **Steady-State Extraction:** Calculates the mean of the final 10% of generations (G<sub>2700</sub>–G<sub>3000</sub>) to determine asymptotic behavior.
4.  **Error Estimation:** Computes 95% Confidence Intervals (CI) using the standard deviation across iterations divided by √500.

## Human Experiment Code
### Environment preparation
python3.8, otree3.4.0
It is recommended to use python virtual environment such as pyenv

```
pip install otree==3.4.0
pip install requests
```
### Modify otree source code（Please modify according to your actual path）
#### Add MyPage class in the following file
Add MyPage class in /lib/python3.8/site-packages/otree/views/abstract.py
Rewrite the get method of Page class and execute on_enter() as soon as the page is entered, which is convenient for communication page and decision page. When the user enters the page, send the task of calling gpt interface to woker

```python
class MyPage(Page):
    def on_enter(self):
        """
        Called when the page is entered.
        You can perform tasks here that need to run when the page loads, for example calling the GPT API.
        """
        # For example, send a task to a worker:
        # send_to_gpt_api(self.participant)

        pass

    def get(self):
        """
        This method is called when the page is loaded.
        Implement custom behavior here:
        - call on_enter() when the page is entered
        - return the response that renders the page
        """
        # If the page is not visible, increment the page index and redirect to the correct page
        if not self._is_displayed():
            self._increment_index_in_pages()
            return self._redirect_to_page_the_user_should_be_on()

        # Call on_enter() when the page is entered
        self.on_enter()

        # Set the URL of the current page
        self.participant._current_form_page_url = self.request.path

        # Retrieve the object associated with the current page (e.g., player or group data)
        self.object = self.get_object()

        # Update the monitor table (usually for debugging or tracking)
        self._update_monitor_table()

        # Get the form associated with this page and its context data
        form = self.get_form(instance=self.object)
        context = self.get_context_data(form=form)

        # Render the response and return it
        response = self.render_to_response(context)

        # Handle browser automation tasks (if any)
        self.browser_bot_stuff(response)

        return response
```

#### Include this class in the following file
- /lib/python3.8/site-packages/otree/views/__init__.py
```python
	from otree.views.abstract import WaitPage, Page, MyPage
```
- /lib/python3.8/site-packages/otree/api.py Add MyPage at the end of the fourth line
```python
	from otree.views import Page, WaitPage, MyPage  # noqa
```
## Human-human game
### Start otree
For details, please refer to the otree official website http://www.otree.org/

You need to first use cd to go to the directory where each settings.py file is located.

```
export OTREE_AUTE_LEVEL=STUDY
export OTREE_PRODUCTION=1
export OTREE_ADMIN_PASSWORD=otreeadmin123
otree resetdb
otree prodserver 9800
```
## Openurl
```
localhost:9800
```

## **Configuration parameters**

Configuration parameters when creating your own experiment.The code for a reward of 1.5 is in pgg_10humans_1.5norm, and the code for a reward of 0.5 is in pgg_10humans_0.5norm.

For a 10-human participant real-person experiment, set the parameters as follows:

**Number of participants**=10

**players_per_group**=10

**with_bot** checkbox: not selected

**norm_c**=0.5(or 1.5 , depending on your experiment type)

**bot_proportion**=0.0

**truth_or_not** checkbox: not selected

### Environment preparation

Install celery

```
pip install celery
```

Install and start RabbitMQ

```
sudo apt-get install rabbitmq-server -y
sudo systemctl start rabbitmq-server
```

Install and start Redis

```
sudo apt-get install redis-server -y
sudo systemctl start redis-server
```
