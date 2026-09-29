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

## Human-machine game

This section documents the human-machine version of the code: the same PGG framework, but participants play in groups containing bots, under one of two disclosure conditions.

### Code layout

```
truthful/    # bots disclosed
deception/   # bots concealed
```

Each directory holds four independent oTree projects. `_main` / `_2` / `_3` / `_4` denote the **stage order**, not four different norm conditions:

```
truthful/otree_pgg_bot_norm-main/otree_pgg_bot_norm-main/settings.py
truthful/otree_pgg_bot_norm-main_2/otree_pgg_bot_norm-main/settings.py
...
```

All 8 `settings.py` are byte-identical (same md5); only each app's `models.py` differs, because the stage order differs. Always `cd` into one project root (the folder containing `settings.py` and `manage.py`) before running. Do not run two projects with the same app names from one working directory.

### Stage conditions

| Stage | `with_norm` | `a_or_not` | `allc_or_not` | Bot strategy |
| :-- | :-- | :-- | :-- | :-- |
| A | True | True | True | invest every round |
| B | True | True | False | keep every round |
| C | False | False | True | invest every round |
| D | False | False | False | keep every round |

- `with_norm` / `a_or_not`: the 1.5-point norm bonus. In this code base they always hold the same value; `a_or_not` drives the wording shown on the screens, `with_norm` drives the actual payoff computation.
- `allc_or_not`: bot strategy — True = all-invest, False = all-keep.

Stage order per project:

| Project | Order |
| :-- | :-- |
| `otree_pgg_bot_norm-main` | A → B → C → D |
| `otree_pgg_bot_norm-main_2` | B → C → D → A |
| `otree_pgg_bot_norm-main_3` | C → D → A → B |
| `otree_pgg_bot_norm-main_4` | D → A → B → C |

Conditions are set through the `default=` values of the `Subsession` fields in each app's `models.py` (commented-out assignments in `creating_session()` are available for temporary overrides). Stage 1 is always `pgg_no_survey` (full instructions: `IntroductionA`, `IntroductionRule`, rule quiz `CheckQues`); stages 2–4 are `pgg_no_two` / `pgg_no_three` / `pgg_no_four` with page sequence `[IntroductionB, ContributeNew, ResultsWaitPage, ResultsNew, FinalResults]`.

### Key session parameters (settings.py)

```python
players_per_group = 8          # human participants
num_demo_participants = 8
init_money = 50
multiplier = 2                 # public pool multiplier
total_round = 10               # rounds actually played per stage (app num_rounds = 20)
timeout_seconds = 40
with_bot = True
bot_proportion = 0.2           # bot share
norm_c = 1.5                   # norm bonus value
truth_or_not = True            # whether the bots are disclosed
app_sequence = ['pgg_no_survey', 'info_collector_one', 'pgg_no_two',
                'info_collector_two', 'pgg_no_three', 'info_collector_three',
                'pgg_no_four', 'info_collector']
```

The number of bots is derived from the proportion, not given directly:

```python
num_bots = int(num_players * bot_proportion / (1 - bot_proportion))
```

With `players_per_group=8` and `bot_proportion=0.2` this yields 2 bots, and participants see a group size of 10.

### Payoff and norm bonus

Each round every individual receives 1 point; "invest" goes into the public pool, "keep" stays in the personal account. The pool is multiplied by `multiplier` and split evenly between humans and bots.

```python
self.group_cur_return = pool / (num_players + num_bots)
p.payoff = self.group_cur_return - p.disc_choice
```

When `with_norm=True`, a participant who matches the majority receives an extra 1.5 points (`norm_payoff`). The majority test uses the hard-coded threshold 5 (`num_contr==5` / `>5` / `<5`), i.e. a 10-person group; change it together with the group size.

### How concealment (deception) is implemented

`truth_or_not` is the only switch. When True, the instructions state that the group may contain bots and show the bot/human icons, and `ContributeNew.html` picks `one.png` (0.1) or `two.png` (0.2) from `bot_proportion`. When False, `IntroductionA.html` takes the `{% else %}` branch and shows "您的小组成员全部都是人类", and the contribution page falls back to `zero.png`.

`truthful/` and `deception/` differ only in these files:

| File | Difference |
| :-- | :-- |
| `pgg_no_survey/templates/.../IntroductionA.html` | deception adds the `{% else %}` branch stating all group members are human |
| `pgg_no_survey/templates/.../CheckQues.html` | deception rewrites Q4 to "您只可以与人类参与者互动" and changes the JS answer key `q4: ['3']` → `['2']` |
| `pgg_no_survey/models.py` | deception hard-codes the first-stage payoff denominator as `pool / 10.0` instead of `pool / (num_players + num_bots)` |
| `pgg_no_*/templates/.../ResultsNew.html` | deception forces the displayed cumulative payoff to `0.0` when `count == 1` |
| `info_collector*/pages.py` + `SurveyMore.html` | deception comments out the `participant_identity` question and renumbers the remaining questions 1–8 |

### Start oTree

```bash
conda activate /sdb/data_public/wanghan/ppg_human_bot/venv   # or your own pyenv/venv

cd truthful/otree_pgg_bot_norm-main/otree_pgg_bot_norm-main   # must be the project root
export OTREE_ADMIN_PASSWORD=otreeadmin123
export OTREE_PRODUCTION=1
otree resetdb
otree prodserver 9800
```

Then open `localhost:9800` and configure the session with the parameters above. The four ordering projects cannot run simultaneously from one working directory; start them separately or on different ports.

(`celery` and RabbitMQ/Redis are described in the Human-human game section above. The human-machine code does not import `MyPage`, so it does not depend on that oTree source patch.)

### Check before running

1. In `deception/`, `truth_or_not` is still `True` in all 8 `settings.py`. Running with the defaults therefore reproduces the **disclosed** condition, not the concealed one; set it to `False` in the session config (or in `settings.py`) to obtain concealment. How this was configured for the original data must be checked separately.
2. In `deception/` `CheckQues.html`, Q4 still carries the `correct-answer` marker on the option whose value is `3`, while the JS key expects `['2']`; the two disagree, so participants may be unable to pass that question.
3. `deception/` hard-codes the first-stage denominator at `10.0`; recompute if the group size or bot proportion changes.
4. `deception/` `ResultsNew.html` displays `0.0` in the first round regardless of the real cumulative payoff.
5. `norm_c` remains 1.5 even for stages with `with_norm=False`; only `with_norm=True` stages actually read it.
6. The full flow has not been run end-to-end here; the statements above come from source and file comparison.
